<?php

namespace App\Services;

use App\Models\Appointment;
use App\Models\ConsentTemplate;
use App\Models\Patient;
use App\Models\PatientConsent;
use App\Models\User;
use App\Repositories\AppointmentRepository;
use App\Repositories\ConsentRepository;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class ConsentService
{
    public function __construct(
        private readonly ConsentRepository $consents,
        private readonly AppointmentRepository $appointments,
        private readonly PatientService $patients,
    ) {
    }

    /**
     * @return Collection<int, ConsentTemplate>
     */
    public function listTemplates(
        User $actor,
        ?string $clinicId = null,
        ?string $consentType = null,
        bool $activeOnly = true,
    ): Collection {
        return $this->consents->templatesForUser($actor, $clinicId, $consentType, $activeOnly);
    }

    /**
     * @return Collection<int, PatientConsent>
     */
    public function patientConsents(User $actor, Patient $patient): Collection
    {
        $patient = $this->patients->summary($actor, $patient);

        return $this->consents->patientConsentsForUser($actor, $patient);
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function capture(User $actor, array $payload): PatientConsent
    {
        $patient = $this->patients->summary(
            $actor,
            Patient::query()->findOrFail((string) $payload['patient_id']),
        );

        $template = $this->consents->templateForUser(
            $actor,
            ConsentTemplate::query()->findOrFail((string) $payload['consent_template_id']),
        );

        if ($template->clinic_id !== $patient->clinic_id) {
            throw ValidationException::withMessages([
                'consent_template_id' => 'The selected consent template is not available for this patient clinic.',
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

        $consent = $this->consents->createConsent([
            'id' => $payload['id'] ?? (string) Str::uuid(),
            'clinic_id' => $patient->clinic_id,
            'patient_id' => $patient->id,
            'appointment_id' => $appointment?->id,
            'consent_template_id' => $template->id,
            'captured_by_user_id' => $actor->id,
            'accepted_by' => trim((string) $payload['accepted_by']),
            'source_channel' => $payload['source_channel'] ?? 'admin_capture',
            'accepted_at' => $payload['accepted_at'] ?? now(),
            'template_version' => $template->version,
            'template_snapshot' => [
                'title' => $template->title,
                'slug' => $template->slug,
                'consent_type' => $template->consent_type,
                'description' => $template->description,
                'body' => $template->body,
                'version' => $template->version,
            ],
            'accepted_payload' => $payload['accepted_payload'] ?? null,
            'notes' => filled($payload['notes'] ?? null) ? trim((string) $payload['notes']) : null,
        ]);

        return $consent->loadMissing(['template', 'patient', 'appointment', 'capturedBy']);
    }
}
