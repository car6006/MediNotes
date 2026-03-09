<?php

namespace App\Repositories;

use App\Models\Clinic;
use App\Models\Encounter;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;

class EncounterRepository
{
    public function paginateForUser(User $user, array $filters, int $perPage = 25): LengthAwarePaginator
    {
        return $this->queryForUser($user, $filters['clinic_id'] ?? null)
            ->when($filters['patient_id'] ?? null, fn (Builder $query, string $patientId) => $query->where('patient_id', $patientId))
            ->when($filters['appointment_id'] ?? null, fn (Builder $query, string $appointmentId) => $query->where('appointment_id', $appointmentId))
            ->when($filters['provider_id'] ?? null, fn (Builder $query, string $providerId) => $query->where('provider_id', $providerId))
            ->when($filters['status'] ?? null, fn (Builder $query, string $status) => $query->where('status', $status))
            ->when($filters['date'] ?? null, fn (Builder $query, string $date) => $query->whereDate('started_at', $date))
            ->orderByDesc('started_at')
            ->orderByDesc('created_at')
            ->paginate($perPage)
            ->withQueryString();
    }

    public function detailForUser(User $user, Encounter $encounter): Encounter
    {
        return $this->queryForUser($user)
            ->whereKey($encounter->getKey())
            ->firstOrFail();
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function create(array $attributes): Encounter
    {
        return Encounter::query()->create($attributes);
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function update(Encounter $encounter, array $attributes): Encounter
    {
        $encounter->fill($attributes);
        $encounter->save();

        return $encounter;
    }

    public function firstAvailableClinicId(): ?string
    {
        return Clinic::query()
            ->where('is_active', true)
            ->orderBy('name')
            ->value('id');
    }

    private function queryForUser(User $user, ?string $requestedClinicId = null): Builder
    {
        $user->loadMissing('providerProfile');

        return Encounter::query()
            ->with([
                'clinic',
                'patient',
                'appointment',
                'provider',
                'clinician',
                'encounterTemplate.encounterSections',
                'audioFiles.uploadedBy',
                'transcripts.audioFile',
                'transcripts.generatedBy',
                'transcripts.reviewedBy',
                'clinicalNote.currentVersion',
                'clinicalNote.versions',
                'currentClinicalNote.currentVersion',
                'currentClinicalNote.createdBy',
                'currentClinicalNote.signedBy',
            ])
            ->withCount(['audioFiles', 'transcripts'])
            ->when(
                ! $user->hasRole('admin') && $user->providerProfile?->clinic_id,
                fn (Builder $query) => $query->where('clinic_id', $user->providerProfile->clinic_id),
                function (Builder $query) use ($user, $requestedClinicId): void {
                    if ($user->hasRole('admin') && filled($requestedClinicId)) {
                        $query->where('clinic_id', $requestedClinicId);
                    }
                },
            );
    }
}