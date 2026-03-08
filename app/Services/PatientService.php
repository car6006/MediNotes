<?php

namespace App\Services;

use App\Models\Patient;
use App\Models\User;
use App\Repositories\PatientRepository;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Arr;
use Illuminate\Support\Str;

class PatientService
{
    public function __construct(
        private readonly PatientRepository $patients,
    ) {
    }

    public function list(User $actor, int $perPage = 25): LengthAwarePaginator
    {
        return $this->patients->paginateForUser($actor, $perPage);
    }

    /**
     * @return Collection<int, Patient>
     */
    public function search(User $actor, string $query, int $limit = 25): Collection
    {
        return $this->patients->searchForUser($actor, trim($query), $limit);
    }

    public function detail(User $actor, Patient $patient): Patient
    {
        return $this->patients->detailForUser($actor, $patient);
    }

    public function summary(User $actor, Patient $patient): Patient
    {
        return $this->patients->summaryForUser($actor, $patient);
    }

    /**
     * @return Collection<int, \App\Models\Visit>
     */
    public function timeline(User $actor, Patient $patient): Collection
    {
        return $this->patients->timelineForUser($actor, $patient);
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function create(User $actor, array $payload): Patient
    {
        $attributes = $this->normalizedPayload($actor, $payload);
        $attributes['id'] = $payload['id'] ?? (string) Str::uuid();
        $attributes['medical_record_number'] = $payload['medical_record_number']
            ?? $this->generateMedicalRecordNumber();

        $patient = $this->patients->create($attributes);

        return $this->detail($actor, $patient);
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function update(User $actor, Patient $patient, array $payload): Patient
    {
        $current = $this->summary($actor, $patient);
        $attributes = $this->normalizedPayload($actor, $payload, $current);

        if (! array_key_exists('medical_record_number', $attributes) && blank($current->medical_record_number)) {
            $attributes['medical_record_number'] = $this->generateMedicalRecordNumber();
        }

        $patient = $this->patients->update($current, $attributes);

        return $this->detail($actor, $patient);
    }

    /**
     * @param  array<string, mixed>  $payload
     * @return array<string, mixed>
     */
    private function normalizedPayload(User $actor, array $payload, ?Patient $existing = null): array
    {
        $attributes = [];

        $scalarFields = [
            'medical_record_number',
            'title',
            'first_name',
            'middle_name',
            'last_name',
            'preferred_name',
            'date_of_birth',
            'sex',
            'phone',
            'alternate_phone',
            'email',
            'national_id_number',
            'passport_number',
            'external_reference',
            'address_line_1',
            'address_line_2',
            'city',
            'province',
            'postal_code',
            'country',
            'emergency_contact_name',
            'emergency_contact_phone',
            'notes',
            'last_visit_at',
        ];

        foreach ($scalarFields as $field) {
            if (array_key_exists($field, $payload)) {
                $attributes[$field] = is_string($payload[$field])
                    ? trim((string) $payload[$field]) ?: null
                    : $payload[$field];
            }
        }

        if (array_key_exists('clinic_id', $payload) || $existing === null) {
            $attributes['clinic_id'] = $this->resolveClinicId($actor, $payload['clinic_id'] ?? null, $existing);
        }

        $allergies = $this->normalizedList($payload, 'allergies', $existing?->allergies ?? []);
        $medications = $this->normalizedList($payload, 'medications', $existing?->medications ?? []);
        $medicalHistory = $this->normalizedList($payload, 'medical_history', $existing?->medical_history ?? []);
        $alerts = $this->normalizedList($payload, 'alerts', $existing?->alerts ?? []);

        if (array_key_exists('allergies', $payload)) {
            $attributes['allergies'] = $allergies;
        }

        if (array_key_exists('medications', $payload)) {
            $attributes['medications'] = $medications;
        }

        if (array_key_exists('medical_history', $payload)) {
            $attributes['medical_history'] = $medicalHistory;
        }

        if (array_key_exists('alerts', $payload)) {
            $attributes['alerts'] = $alerts;
            $attributes['has_alerts'] = $alerts !== [];
        }

        if (array_key_exists('allergies_summary', $payload) || array_key_exists('allergies', $payload)) {
            $attributes['allergies_summary'] = $this->summaryText($payload['allergies_summary'] ?? null, $allergies);
        }

        if (array_key_exists('medication_summary', $payload) || array_key_exists('medications', $payload)) {
            $attributes['medication_summary'] = $this->summaryText($payload['medication_summary'] ?? null, $medications);
        }

        if (array_key_exists('medical_history_summary', $payload) || array_key_exists('medical_history', $payload)) {
            $attributes['medical_history_summary'] = $this->summaryText($payload['medical_history_summary'] ?? null, $medicalHistory);
        }

        return $attributes;
    }

    /**
     * @param  array<string, mixed>  $payload
     * @param  list<string>  $default
     * @return list<string>
     */
    private function normalizedList(array $payload, string $key, array $default = []): array
    {
        if (! array_key_exists($key, $payload)) {
            return $default;
        }

        $items = Arr::wrap($payload[$key]);

        return array_values(array_filter(array_map(static fn (mixed $item): string => trim((string) $item), $items)));
    }

    private function summaryText(?string $explicitSummary, array $items): ?string
    {
        $explicitSummary = $explicitSummary !== null ? trim($explicitSummary) : null;

        if ($explicitSummary !== null && $explicitSummary !== '') {
            return $explicitSummary;
        }

        return $items === [] ? null : implode('; ', $items);
    }

    private function resolveClinicId(User $actor, ?string $requestedClinicId, ?Patient $existing = null): ?string
    {
        $actor->loadMissing('providerProfile');

        if ($actor->hasRole('admin') && filled($requestedClinicId)) {
            return $requestedClinicId;
        }

        return $existing?->clinic_id
            ?? $actor->providerProfile?->clinic_id
            ?? $requestedClinicId
            ?? $this->patients->firstAvailableClinicId();
    }

    private function generateMedicalRecordNumber(): string
    {
        do {
            $candidate = 'MRN-'.now()->format('ymd').'-'.str_pad((string) random_int(1, 9999), 4, '0', STR_PAD_LEFT);
        } while (Patient::query()->where('medical_record_number', $candidate)->exists());

        return $candidate;
    }
}
