<?php

namespace App\Services;

use App\Enums\EncounterStatus;
use App\Models\Appointment;
use App\Models\AudioFile;
use App\Models\Encounter;
use App\Models\Patient;
use App\Models\Provider;
use App\Models\User;
use App\Repositories\AudioFileRepository;
use App\Repositories\EncounterRepository;
use App\Support\EncounterStateMachine;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Validation\ValidationException;
use Illuminate\Support\Str;

class EncounterService
{
    /**
     * @var list<string>
     */
    private const DIRECT_STATUS_TARGETS = [
        EncounterStatus::IN_PROGRESS->value,
        EncounterStatus::COMPLETED->value,
    ];

    public function __construct(
        private readonly EncounterRepository $encounters,
        private readonly AudioFileRepository $audioFiles,
        private readonly PatientService $patients,
        private readonly AppointmentService $appointments,
        private readonly EncounterTemplateService $templates,
        private readonly EncounterStateMachine $stateMachine,
    ) {
    }

    /**
     * @param  array<string, mixed>  $filters
     */
    public function list(User $actor, array $filters, int $perPage = 25): LengthAwarePaginator
    {
        return $this->encounters->paginateForUser($actor, $filters, $perPage);
    }

    public function detail(User $actor, Encounter $encounter): Encounter
    {
        return $this->encounters->detailForUser($actor, $encounter);
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function create(User $actor, array $payload): Encounter
    {
        $appointment = $this->resolveAppointment($actor, $payload['appointment_id'] ?? null);
        $patient = $this->resolvePatient($actor, $payload['patient_id'] ?? null, $appointment);
        $clinicId = $this->resolveClinicId($actor, $payload['clinic_id'] ?? null, $patient, $appointment);
        $provider = $this->resolveProvider($actor, $clinicId, $payload['provider_id'] ?? null, $appointment);

        $template = $this->templates->resolve(
            actor: $actor,
            templateId: $payload['encounter_template_id'] ?? null,
            clinicId: $clinicId,
        );

        $encounter = $this->encounters->create([
            'id' => $payload['id'] ?? (string) Str::uuid(),
            'clinic_id' => $clinicId,
            'patient_id' => $patient->id,
            'appointment_id' => $appointment?->id,
            'provider_id' => $provider?->id,
            'clinician_id' => $provider?->user_id ?? $actor->id,
            'encounter_template_id' => $template?->id,
            'encounter_type' => $this->normalizedString($payload['encounter_type'] ?? ($appointment ? 'scheduled_consult' : 'clinical_encounter')),
            'status' => EncounterStatus::CREATED->value,
            'status_changed_at' => now(),
            'chief_complaint' => $this->normalizedString($payload['chief_complaint'] ?? $appointment?->reason_for_visit),
            'template_snapshot' => $template ? [
                'id' => $template->id,
                'title' => $template->title,
                'version' => $template->version,
                'specialty' => $template->specialty,
                'note_format' => $template->note_format,
            ] : null,
            'privacy_notice_acknowledged_at' => $payload['privacy_notice_acknowledged_at'] ?? null,
            'recording_consent_obtained_at' => $payload['recording_consent_obtained_at'] ?? null,
            'recording_consent_method' => $this->normalizedString($payload['recording_consent_method'] ?? null),
            'ai_transcription_consent_obtained_at' => $payload['ai_transcription_consent_obtained_at'] ?? null,
            'consent_notes' => $this->normalizedString($payload['consent_notes'] ?? null),
            'meta' => $payload['meta'] ?? null,
            'started_at' => $payload['started_at'] ?? null,
        ]);

        $patient->forceFill([
            'last_visit_at' => $encounter->started_at ?? now(),
        ])->save();

        return $this->detail($actor, $encounter);
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function update(User $actor, Encounter $encounter, array $payload): Encounter
    {
        $current = $this->detail($actor, $encounter);
        $attributes = [];

        foreach (['chief_complaint', 'encounter_type', 'consent_notes', 'patient_update', 'meta'] as $field) {
            if (array_key_exists($field, $payload)) {
                $attributes[$field] = is_string($payload[$field])
                    ? $this->normalizedString($payload[$field])
                    : $payload[$field];
            }
        }

        foreach ([
            'privacy_notice_acknowledged_at',
            'recording_consent_obtained_at',
            'recording_consent_method',
            'ai_transcription_consent_obtained_at',
            'started_at',
        ] as $field) {
            if (array_key_exists($field, $payload)) {
                $attributes[$field] = $field === 'recording_consent_method'
                    ? $this->normalizedString($payload[$field])
                    : $payload[$field];
            }
        }

        if (array_key_exists('encounter_template_id', $payload)) {
            $template = $this->templates->resolve($actor, $payload['encounter_template_id'], $current->clinic_id);
            $attributes['encounter_template_id'] = $template?->id;
            $attributes['template_snapshot'] = $template ? [
                'id' => $template->id,
                'title' => $template->title,
                'version' => $template->version,
                'specialty' => $template->specialty,
                'note_format' => $template->note_format,
            ] : null;
        }

        if (array_key_exists('provider_id', $payload)) {
            $provider = $this->resolveProvider($actor, $current->clinic_id, $payload['provider_id'], null);
            $attributes['provider_id'] = $provider?->id;
            $attributes['clinician_id'] = $provider?->user_id ?? $current->clinician_id;
        }

        if (array_key_exists('status', $payload)) {
            $target = EncounterStatus::from((string) $payload['status']);

            if (! in_array($target->value, self::DIRECT_STATUS_TARGETS, true)) {
                throw ValidationException::withMessages([
                    'status' => 'This encounter state is managed by transcript or clinical note workflows.',
                ]);
            }

            if ($target === EncounterStatus::COMPLETED && $current->currentClinicalNote?->status !== 'signed_off') {
                throw ValidationException::withMessages([
                    'status' => 'Encounters can only be completed after the current clinical note is signed off.',
                ]);
            }

            $attributes = [...$attributes, ...$this->stateMachine->transition($current, $target)];
        }

        $encounter = $this->encounters->update($current, $attributes);

        return $this->detail($actor, $encounter);
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function registerAudio(User $actor, Encounter $encounter, array $payload): AudioFile
    {
        $current = $this->detail($actor, $encounter);

        $this->ensureRecordingConsent($current);

        $audio = $this->audioFiles->create([
            'id' => $payload['id'] ?? (string) Str::uuid(),
            'encounter_id' => $current->id,
            'uploaded_by_user_id' => $actor->id,
            'storage_disk' => $this->normalizedString($payload['storage_disk'] ?? 'private') ?? 'private',
            'storage_path' => trim((string) $payload['storage_path']),
            'original_filename' => $this->normalizedString($payload['original_filename'] ?? null),
            'mime_type' => $this->normalizedString($payload['mime_type'] ?? null),
            'file_size_bytes' => $payload['file_size_bytes'] ?? null,
            'duration_seconds' => $payload['duration_seconds'] ?? null,
            'checksum_sha256' => $this->normalizedString($payload['checksum_sha256'] ?? null),
            'capture_mode' => $this->normalizedString($payload['capture_mode'] ?? 'offline_whisper') ?? 'offline_whisper',
            'captured_at' => $payload['captured_at'] ?? now(),
            'meta' => $payload['meta'] ?? null,
        ]);

        $transitionAttributes = $this->stateMachine->progress($current, EncounterStatus::DICTATION_CAPTURED);

        if ($transitionAttributes !== []) {
            $this->encounters->update($current, $transitionAttributes);
        }

        return $audio->load('uploadedBy');
    }

    private function ensureRecordingConsent(Encounter $encounter): void
    {
        if (! config('clinical.dictation.require_recording_consent', true)) {
            return;
        }

        if ($encounter->privacy_notice_acknowledged_at === null) {
            throw ValidationException::withMessages([
                'privacy_notice_acknowledged_at' => 'Privacy notice acknowledgement is required before recording encounter audio.',
            ]);
        }

        if ($encounter->recording_consent_obtained_at === null) {
            throw ValidationException::withMessages([
                'recording_consent_obtained_at' => 'Recording consent is required before recording encounter audio.',
            ]);
        }

        if (blank($encounter->recording_consent_method)) {
            throw ValidationException::withMessages([
                'recording_consent_method' => 'Recording consent method is required before recording encounter audio.',
            ]);
        }
    }

    private function resolveAppointment(User $actor, ?string $appointmentId): ?Appointment
    {
        if (blank($appointmentId)) {
            return null;
        }

        return $this->appointments->detail($actor, Appointment::query()->findOrFail($appointmentId));
    }

    private function resolvePatient(User $actor, ?string $patientId, ?Appointment $appointment): Patient
    {
        if (filled($patientId)) {
            $patient = $this->patients->summary($actor, Patient::query()->findOrFail($patientId));

            if ($appointment !== null && $appointment->patient_id !== $patient->id) {
                throw ValidationException::withMessages([
                    'patient_id' => 'The selected patient does not match the chosen appointment.',
                ]);
            }

            return $patient;
        }

        if ($appointment?->patient) {
            return $this->patients->summary($actor, $appointment->patient);
        }

        throw ValidationException::withMessages([
            'patient_id' => 'A visible patient is required to create an encounter.',
        ]);
    }

    private function resolveClinicId(User $actor, ?string $requestedClinicId, Patient $patient, ?Appointment $appointment): string
    {
        $actor->loadMissing('providerProfile');

        $clinicId = ($actor->hasRole('admin') && filled($requestedClinicId))
            ? $requestedClinicId
            : ($actor->providerProfile?->clinic_id
                ?? $appointment?->clinic_id
                ?? $patient->clinic_id
                ?? $requestedClinicId
                ?? $this->encounters->firstAvailableClinicId());

        if (! is_string($clinicId) || $clinicId === '') {
            throw ValidationException::withMessages([
                'clinic_id' => 'A clinic is required before an encounter can be created.',
            ]);
        }

        if ($patient->clinic_id !== null && $patient->clinic_id !== $clinicId) {
            throw ValidationException::withMessages([
                'patient_id' => 'The selected patient does not belong to the resolved clinic.',
            ]);
        }

        if ($appointment !== null && $appointment->clinic_id !== $clinicId) {
            throw ValidationException::withMessages([
                'appointment_id' => 'The selected appointment does not belong to the resolved clinic.',
            ]);
        }

        return $clinicId;
    }

    private function resolveProvider(User $actor, string $clinicId, ?string $providerId, ?Appointment $appointment): ?Provider
    {
        $resolvedId = $providerId ?? $appointment?->provider_id;

        if (blank($resolvedId)) {
            $actor->loadMissing('providerProfile');

            if ($actor->providerProfile?->clinic_id === $clinicId) {
                return $actor->providerProfile;
            }

            return null;
        }

        $provider = Provider::query()->findOrFail($resolvedId);

        if ($provider->clinic_id !== $clinicId) {
            throw ValidationException::withMessages([
                'provider_id' => 'The selected provider does not belong to the resolved clinic.',
            ]);
        }

        return $provider;
    }

    private function normalizedString(mixed $value): ?string
    {
        if (! is_string($value)) {
            return $value;
        }

        $trimmed = trim($value);

        return $trimmed === '' ? null : $trimmed;
    }
}