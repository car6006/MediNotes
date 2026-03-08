<?php

namespace App\Repositories;

use App\Models\Patient;
use App\Models\User;
use App\Models\Visit;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;

class PatientRepository
{
    public function paginateForUser(User $user, int $perPage = 25): LengthAwarePaginator
    {
        return $this->queryForUser($user)
            ->latest('updated_at')
            ->paginate($perPage)
            ->withQueryString();
    }

    public function searchForUser(User $user, string $search, int $limit = 25): Collection
    {
        return $this->queryForUser($user)
            ->where(function (Builder $query) use ($search): void {
                $query
                    ->where('first_name', 'like', "%{$search}%")
                    ->orWhere('middle_name', 'like', "%{$search}%")
                    ->orWhere('last_name', 'like', "%{$search}%")
                    ->orWhere('preferred_name', 'like', "%{$search}%")
                    ->orWhere('medical_record_number', 'like', "%{$search}%")
                    ->orWhere('national_id_number', 'like', "%{$search}%")
                    ->orWhere('passport_number', 'like', "%{$search}%")
                    ->orWhere('external_reference', 'like', "%{$search}%")
                    ->orWhere('phone', 'like', "%{$search}%")
                    ->orWhere('alternate_phone', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            })
            ->latest('updated_at')
            ->limit($limit)
            ->get();
    }

    public function detailForUser(User $user, Patient $patient): Patient
    {
        return $this->queryForUser($user)
            ->with([
                'clinic',
                'visits.template',
                'visits.dictations',
            ])
            ->whereKey($patient->getKey())
            ->firstOrFail();
    }

    public function summaryForUser(User $user, Patient $patient): Patient
    {
        return $this->queryForUser($user)
            ->whereKey($patient->getKey())
            ->firstOrFail();
    }

    /**
     * @return Collection<int, Visit>
     */
    public function timelineForUser(User $user, Patient $patient): Collection
    {
        $visiblePatient = $this->summaryForUser($user, $patient);

        return Visit::query()
            ->with('template')
            ->withCount('dictations')
            ->where('patient_id', $visiblePatient->id)
            ->latest('started_at')
            ->get();
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function create(array $attributes): Patient
    {
        return Patient::query()->create($attributes);
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function update(Patient $patient, array $attributes): Patient
    {
        $patient->fill($attributes);
        $patient->save();

        return $patient;
    }

    public function firstAvailableClinicId(): ?string
    {
        return \App\Models\Clinic::query()
            ->where('is_active', true)
            ->orderBy('name')
            ->value('id');
    }

    private function queryForUser(User $user): Builder
    {
        $user->loadMissing('providerProfile');

        return Patient::query()
            ->with('clinic')
            ->withCount('visits')
            ->when(
                ! $user->hasRole('admin') && $user->providerProfile?->clinic_id,
                fn (Builder $query) => $query->where('clinic_id', $user->providerProfile->clinic_id),
            );
    }
}
