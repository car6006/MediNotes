<?php

namespace App\Repositories;

use App\Models\Appointment;
use App\Models\Clinic;
use App\Models\Patient;
use App\Models\Provider;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;

class AppointmentRepository
{
    public function paginateForUser(User $user, array $filters, int $perPage = 25): LengthAwarePaginator
    {
        return $this->queryForUser($user, $filters['clinic_id'] ?? null)
            ->when($filters['patient_id'] ?? null, fn (Builder $query, string $patientId) => $query->where('patient_id', $patientId))
            ->when($filters['provider_id'] ?? null, fn (Builder $query, string $providerId) => $query->where('provider_id', $providerId))
            ->when($filters['status'] ?? null, fn (Builder $query, string $status) => $query->where('status', $status))
            ->when($filters['date'] ?? null, fn (Builder $query, string $date) => $query->whereDate('scheduled_for', $date))
            ->orderBy('scheduled_for')
            ->paginate($perPage)
            ->withQueryString();
    }

    public function detailForUser(User $user, Appointment $appointment): Appointment
    {
        return $this->queryForUser($user)
            ->whereKey($appointment->getKey())
            ->firstOrFail();
    }

    /**
     * @return Collection<int, Appointment>
     */
    public function patientAppointmentsForUser(User $user, Patient $patient): Collection
    {
        return $this->queryForUser($user)
            ->where('patient_id', $patient->id)
            ->orderByDesc('scheduled_for')
            ->get();
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function create(array $attributes): Appointment
    {
        return Appointment::query()->create($attributes);
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function update(Appointment $appointment, array $attributes): Appointment
    {
        $appointment->fill($attributes);
        $appointment->save();

        return $appointment;
    }

    public function firstAvailableClinicId(): ?string
    {
        return Clinic::query()
            ->where('is_active', true)
            ->orderBy('name')
            ->value('id');
    }

    public function firstAvailableProviderId(?string $clinicId): ?string
    {
        if ($clinicId === null) {
            return null;
        }

        return Provider::query()
            ->where('clinic_id', $clinicId)
            ->where('is_active', true)
            ->orderBy('last_name')
            ->orderBy('first_name')
            ->value('id');
    }

    private function queryForUser(User $user, ?string $requestedClinicId = null): Builder
    {
        $user->loadMissing('providerProfile');

        return Appointment::query()
            ->with(['clinic', 'patient', 'provider', 'bookedBy'])
            ->withCount(['onboardingResponses', 'consents'])
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
