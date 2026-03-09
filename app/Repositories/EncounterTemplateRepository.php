<?php

namespace App\Repositories;

use App\Models\EncounterTemplate;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;

class EncounterTemplateRepository
{
    /**
     * @param  array<string, mixed>  $filters
     * @return Collection<int, EncounterTemplate>
     */
    public function listForUser(User $user, array $filters = []): Collection
    {
        return $this->queryForUser($user, $filters['clinic_id'] ?? null)
            ->when(array_key_exists('specialty', $filters) && filled($filters['specialty'] ?? null), fn (Builder $query) => $query->where('specialty', trim((string) $filters['specialty'])))
            ->when(array_key_exists('active', $filters), fn (Builder $query) => $query->where('is_active', (bool) $filters['active']))
            ->orderByDesc('is_system')
            ->orderBy('title')
            ->orderBy('version')
            ->get();
    }

    public function detailForUser(User $user, string $templateId): EncounterTemplate
    {
        return $this->queryForUser($user)
            ->whereKey($templateId)
            ->firstOrFail();
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function create(array $attributes): EncounterTemplate
    {
        return EncounterTemplate::query()->create($attributes);
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function update(EncounterTemplate $template, array $attributes): EncounterTemplate
    {
        $template->fill($attributes);
        $template->save();

        return $template;
    }

    public function defaultForUser(User $user, ?string $clinicId = null): ?EncounterTemplate
    {
        return $this->queryForUser($user, $clinicId)
            ->where('is_active', true)
            ->orderByDesc('is_system')
            ->orderBy('title')
            ->first();
    }

    private function queryForUser(User $user, ?string $requestedClinicId = null): Builder
    {
        $user->loadMissing('providerProfile');

        return EncounterTemplate::query()
            ->with(['clinic', 'author', 'encounterSections'])
            ->when(
                ! $user->hasRole('admin') && $user->providerProfile?->clinic_id,
                fn (Builder $query) => $query->where(function (Builder $scope) use ($user): void {
                    $scope
                        ->whereNull('clinic_id')
                        ->orWhere('clinic_id', $user->providerProfile->clinic_id);
                }),
                function (Builder $query) use ($user, $requestedClinicId): void {
                    if ($user->hasRole('admin') && filled($requestedClinicId)) {
                        $query->where(function (Builder $scope) use ($requestedClinicId): void {
                            $scope
                                ->whereNull('clinic_id')
                                ->orWhere('clinic_id', $requestedClinicId);
                        });
                    }
                },
            );
    }
}