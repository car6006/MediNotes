<?php

namespace App\Repositories;

use App\Models\OnboardingForm;
use App\Models\OnboardingResponse;
use App\Models\Patient;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;

class OnboardingRepository
{
    /**
     * @return Collection<int, OnboardingForm>
     */
    public function formsForUser(User $user, ?string $clinicId = null, bool $activeOnly = true): Collection
    {
        return $this->formQueryForUser($user, $clinicId)
            ->when($activeOnly, fn (Builder $query) => $query->where('is_active', true))
            ->orderBy('title')
            ->get();
    }

    public function formForUser(User $user, OnboardingForm $form): OnboardingForm
    {
        return $this->formQueryForUser($user)
            ->whereKey($form->getKey())
            ->firstOrFail();
    }

    /**
     * @return Collection<int, OnboardingResponse>
     */
    public function patientResponsesForUser(User $user, Patient $patient): Collection
    {
        return $this->responseQueryForUser($user)
            ->where('patient_id', $patient->id)
            ->orderByDesc('submitted_at')
            ->get();
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function createResponse(array $attributes): OnboardingResponse
    {
        return OnboardingResponse::query()->create($attributes);
    }

    private function formQueryForUser(User $user, ?string $requestedClinicId = null): Builder
    {
        $user->loadMissing('providerProfile');

        return OnboardingForm::query()
            ->with(['clinic', 'creator'])
            ->when(
                ! $user->hasRole('admin') && $user->providerProfile?->clinic_id,
                fn (Builder $query) => $query->where(function (Builder $nested) use ($user): void {
                    $nested->whereNull('clinic_id')->orWhere('clinic_id', $user->providerProfile->clinic_id);
                }),
                function (Builder $query) use ($user, $requestedClinicId): void {
                    if ($user->hasRole('admin') && filled($requestedClinicId)) {
                        $query->where(function (Builder $nested) use ($requestedClinicId): void {
                            $nested->whereNull('clinic_id')->orWhere('clinic_id', $requestedClinicId);
                        });
                    } elseif (! $user->hasRole('admin')) {
                        $query->whereNull('clinic_id');
                    }
                },
            );
    }

    private function responseQueryForUser(User $user): Builder
    {
        $user->loadMissing('providerProfile');

        return OnboardingResponse::query()
            ->with(['form', 'patient', 'appointment', 'submittedBy'])
            ->when(
                ! $user->hasRole('admin') && $user->providerProfile?->clinic_id,
                fn (Builder $query) => $query->where('clinic_id', $user->providerProfile->clinic_id),
            );
    }
}
