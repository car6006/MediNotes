<?php

namespace App\Services;

use App\Models\Appointment;
use App\Models\Patient;
use App\Models\Provider;
use App\Models\User;
use App\Repositories\AppointmentRepository;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class AppointmentService
{
    private const STATUS_TIMESTAMPS = [
        'confirmed' => 'confirmed_at',
        'arrived' => 'arrived_at',
        'in_consult' => 'in_consult_at',
        'completed' => 'completed_at',
        'cancelled' => 'cancelled_at',
        'no_show' => 'no_show_at',
    ];

    public function __construct(
        private readonly AppointmentRepository $appointments,
        private readonly PatientService $patients,
    ) {
    }

    /**
     * @param  array<string, mixed>  $filters
     */
    public function list(User $actor, array $filters, int $perPage = 25): LengthAwarePaginator
    {
        return $this->appointments->paginateForUser($actor, $filters, $perPage);
    }

    public function detail(User $actor, Appointment $appointment): Appointment
    {
        return $this->appointments->detailForUser($actor, $appointment);
    }

    /**
     * @return Collection<int, Appointment>
     */
    public function patientAppointments(User $actor, Patient $patient): Collection
    {
        $patient = $this->patients->summary($actor, $patient);

        return $this->appointments->patientAppointmentsForUser($actor, $patient);
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function create(User $actor, array $payload): Appointment
    {
        $attributes = $this->normalizedPayload($actor, $payload);
        $attributes['id'] = $payload['id'] ?? (string) Str::uuid();

        $appointment = $this->appointments->create($attributes);

        return $this->detail($actor, $appointment);
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function update(User $actor, Appointment $appointment, array $payload): Appointment
    {
        $current = $this->detail($actor, $appointment);
        $attributes = $this->normalizedPayload($actor, $payload, $current);

        $appointment = $this->appointments->update($current, $attributes);

        return $this->detail($actor, $appointment);
    }

    /**
     * @param  array<string, mixed>  $payload
     * @return array<string, mixed>
     */
    private function normalizedPayload(User $actor, array $payload, ?Appointment $existing = null): array
    {
        $existingPatient = $existing?->patient;
        $requestedPatientId = $this->payloadValue($payload, 'patient_id');
        $clinicHint = $requestedPatientId
            ? $this->visiblePatient($actor, (string) $requestedPatientId)->clinic_id
            : $existingPatient?->clinic_id;

        $clinicId = $this->resolveClinicId(
            actor: $actor,
            requestedClinicId: $this->payloadValue($payload, 'clinic_id'),
            clinicHint: $clinicHint,
            existing: $existing,
        );

        $patient = $this->resolvePatient($actor, $clinicId, $payload, $existing);
        $providerId = $this->resolveProviderId($clinicId, $this->payloadValue($payload, 'provider_id', $existing?->provider_id));
        $status = (string) ($this->payloadValue($payload, 'status', $existing?->status ?? 'booked') ?? 'booked');
        $scheduledFor = $this->payloadValue($payload, 'scheduled_for', $existing?->scheduled_for);

        if ($scheduledFor === null) {
            throw ValidationException::withMessages([
                'scheduled_for' => 'A scheduled appointment date and time is required.',
            ]);
        }

        $attributes = [
            'clinic_id' => $clinicId,
            'patient_id' => $patient->id,
            'provider_id' => $providerId,
            'booked_by_user_id' => $existing?->booked_by_user_id ?? $actor->id,
            'booking_type' => $this->resolveBookingType($payload, $existing),
            'status' => $status,
            'scheduled_for' => $scheduledFor,
            'duration_minutes' => (int) ($this->payloadValue($payload, 'duration_minutes', $existing?->duration_minutes ?? 30) ?? 30),
            'reason_for_visit' => $this->trimmedPayloadValue($payload, 'reason_for_visit', $existing?->reason_for_visit),
            'notes' => $this->trimmedPayloadValue($payload, 'notes', $existing?->notes),
            'booking_channel' => (string) ($this->payloadValue($payload, 'booking_channel', $existing?->booking_channel ?? 'admin_capture') ?? 'admin_capture'),
            'cancellation_reason' => $this->trimmedPayloadValue($payload, 'cancellation_reason', $existing?->cancellation_reason),
            'metadata' => $this->payloadValue($payload, 'metadata', $existing?->metadata),
        ];

        return [
            ...$attributes,
            ...$this->statusTimestamps($status, $existing),
        ];
    }

    private function resolvePatient(User $actor, string $clinicId, array $payload, ?Appointment $existing = null): Patient
    {
        $patientId = $this->payloadValue($payload, 'patient_id');

        if (filled($patientId)) {
            $patient = $this->visiblePatient($actor, (string) $patientId);
            $this->ensurePatientClinicMatch($patient, $clinicId);

            return $patient;
        }

        $patientPayload = $this->payloadValue($payload, 'patient');

        if (is_array($patientPayload)) {
            return $this->patients->create($actor, [
                ...$patientPayload,
                'clinic_id' => $clinicId,
            ]);
        }

        if ($existing?->patient) {
            $patient = $this->patients->summary($actor, $existing->patient);
            $this->ensurePatientClinicMatch($patient, $clinicId);

            return $patient;
        }

        throw ValidationException::withMessages([
            'patient_id' => 'An existing patient or new patient booking payload is required.',
        ]);
    }

    private function visiblePatient(User $actor, string $patientId): Patient
    {
        $patient = Patient::query()->findOrFail($patientId);

        return $this->patients->summary($actor, $patient);
    }

    private function ensurePatientClinicMatch(Patient $patient, string $clinicId): void
    {
        if ($patient->clinic_id === $clinicId) {
            return;
        }

        throw ValidationException::withMessages([
            'patient_id' => 'The selected patient does not belong to the resolved clinic.',
        ]);
    }

    private function resolveProviderId(string $clinicId, mixed $providerId): ?string
    {
        if (blank($providerId)) {
            return null;
        }

        $provider = Provider::query()->findOrFail((string) $providerId);

        if ($provider->clinic_id !== $clinicId) {
            throw ValidationException::withMessages([
                'provider_id' => 'The selected provider does not belong to the resolved clinic.',
            ]);
        }

        return $provider->id;
    }

    private function resolveClinicId(User $actor, mixed $requestedClinicId, ?string $clinicHint, ?Appointment $existing = null): string
    {
        $actor->loadMissing('providerProfile');

        $resolved = ($actor->hasRole('admin') && filled($requestedClinicId))
            ? (string) $requestedClinicId
            : ($actor->providerProfile?->clinic_id
                ?? $clinicHint
                ?? $existing?->clinic_id
                ?? (filled($requestedClinicId) ? (string) $requestedClinicId : null)
                ?? $this->appointments->firstAvailableClinicId());

        if (! is_string($resolved) || $resolved === '') {
            throw ValidationException::withMessages([
                'clinic_id' => 'A clinic is required before an appointment can be booked.',
            ]);
        }

        return $resolved;
    }

    private function resolveBookingType(array $payload, ?Appointment $existing = null): string
    {
        $explicit = $this->payloadValue($payload, 'booking_type');

        if (is_string($explicit) && $explicit !== '') {
            return $explicit;
        }

        if (array_key_exists('patient', $payload) && is_array($payload['patient'])) {
            return 'new_patient';
        }

        if (filled($this->payloadValue($payload, 'patient_id'))) {
            return 'returning_patient';
        }

        return $existing?->booking_type ?? 'returning_patient';
    }

    /**
     * @return array<string, mixed>
     */
    private function statusTimestamps(string $status, ?Appointment $existing = null): array
    {
        $attributes = [];

        foreach (self::STATUS_TIMESTAMPS as $state => $column) {
            $attributes[$column] = $existing?->{$column};

            if ($status === $state && $attributes[$column] === null) {
                $attributes[$column] = now();
            }
        }

        return $attributes;
    }

    private function trimmedPayloadValue(array $payload, string $key, mixed $default = null): mixed
    {
        $value = $this->payloadValue($payload, $key, $default);

        if (! is_string($value)) {
            return $value;
        }

        $trimmed = trim($value);

        return $trimmed === '' ? null : $trimmed;
    }

    private function payloadValue(array $payload, string $key, mixed $default = null): mixed
    {
        return array_key_exists($key, $payload) ? $payload[$key] : $default;
    }
}
