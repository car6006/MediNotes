<?php

namespace App\Repositories;

use App\Models\ConsentTemplate;
use App\Models\Patient;
use App\Models\PatientConsent;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;

class ConsentRepository
{
    /**
     * @return Collection<int, ConsentTemplate>
     */
    public function templatesForUser(
        User $user,
        ?string $clinicId = null,
        ?string $consentType = null,
        bool $activeOnly = true,
    ): Collection {
        return $this->templateQueryForUser($user, $clinicId)
            ->when($consentType, fn (Builder $query, string $type) => $query->where('consent_type', $type))
            ->when($activeOnly, fn (Builder $query) => $query->where('is_active', true))
            ->orderBy('title')
            ->get();
    }

    public function templateForUser(User $user, ConsentTemplate $template): ConsentTemplate
    {
        return $this->templateQueryForUser($user)
            ->whereKey($template->getKey())
            ->firstOrFail();
    }

    /**
     * @return Collection<int, PatientConsent>
     */
    public function patientConsentsForUser(User $user, Patient $patient): Collection
    {
        return $this->consentQueryForUser($user)
            ->where('patient_id', $patient->id)
            ->orderByDesc('accepted_at')
            ->get();
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function createConsent(array $attributes): PatientConsent
    {
        return PatientConsent::query()->create($attributes);
    }

    private function templateQueryForUser(User $user, ?string $requestedClinicId = null): Builder
    {
        $user->loadMissing('providerProfile');

        return ConsentTemplate::query()
            ->with(['clinic', 'creator'])
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

    private function consentQueryForUser(User $user): Builder
    {
        $user->loadMissing('providerProfile');

        return PatientConsent::query()
            ->with(['template', 'patient', 'appointment', 'capturedBy'])
            ->when(
                ! $user->hasRole('admin') && $user->providerProfile?->clinic_id,
                fn (Builder $query) => $query->where('clinic_id', $user->providerProfile->clinic_id),
            );
    }
}
