<?php

namespace App\Services;

use App\Models\Appointment;
use App\Models\OnboardingForm;
use App\Models\OnboardingResponse;
use App\Models\Patient;
use App\Models\User;
use App\Repositories\AppointmentRepository;
use App\Repositories\OnboardingRepository;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class OnboardingService
{
    public function __construct(
        private readonly OnboardingRepository $onboarding,
        private readonly AppointmentRepository $appointments,
        private readonly PatientService $patients,
    ) {
    }

    /**
     * @return Collection<int, OnboardingForm>
     */
    public function listForms(User $actor, ?string $clinicId = null, bool $activeOnly = true): Collection
    {
        return $this->onboarding->formsForUser($actor, $clinicId, $activeOnly);
    }

    /**
     * @return Collection<int, OnboardingResponse>
     */
    public function patientResponses(User $actor, Patient $patient): Collection
    {
        $patient = $this->patients->summary($actor, $patient);

        return $this->onboarding->patientResponsesForUser($actor, $patient);
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function submit(User $actor, array $payload): OnboardingResponse
    {
        $patient = $this->patients->summary(
            $actor,
            Patient::query()->findOrFail((string) $payload['patient_id']),
        );

        $form = $this->onboarding->formForUser(
            $actor,
            OnboardingForm::query()->findOrFail((string) $payload['onboarding_form_id']),
        );

        if ($form->clinic_id !== null && $form->clinic_id !== $patient->clinic_id) {
            throw ValidationException::withMessages([
                'onboarding_form_id' => 'The selected onboarding form is not available for this patient clinic.',
            ]);
        }

        $appointment = null;

        if (filled($payload['appointment_id'] ?? null)) {
            $appointment = $this->appointments->detailForUser(
                $actor,
                Appointment::query()->findOrFail((string) $payload['appointment_id']),
            );

            if ($appointment->patient_id !== $patient->id) {
                throw ValidationException::withMessages([
                    'appointment_id' => 'The selected appointment does not belong to the patient.',
                ]);
            }
        }

        $response = $this->onboarding->createResponse([
            'id' => $payload['id'] ?? (string) Str::uuid(),
            'clinic_id' => $patient->clinic_id,
            'patient_id' => $patient->id,
            'appointment_id' => $appointment?->id,
            'onboarding_form_id' => $form->id,
            'submitted_by_user_id' => $actor->id,
            'source_channel' => $payload['source_channel'] ?? 'admin_capture',
            'responses' => $payload['responses'],
            'submitted_at' => $payload['submitted_at'] ?? now(),
        ]);

        return $response->loadMissing(['form', 'patient', 'appointment', 'submittedBy']);
    }
}
