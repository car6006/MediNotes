<?php

namespace App\Concerns;

use App\Models\Permission;
use App\Models\Role;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Support\Collection;

trait HasRolesAndPermissions
{
    public function roles(): BelongsToMany
    {
        return $this->belongsToMany(Role::class)
            ->withTimestamps();
    }

    /**
     * @return Collection<int, Permission>
     */
    public function permissions(): Collection
    {
        $this->loadMissing('roles.permissions');

        return $this->roles
            ->flatMap(fn (Role $role) => $role->permissions)
            ->unique('id')
            ->values();
    }

    public function primaryRole(): ?Role
    {
        $this->loadMissing('roles');

        foreach (['admin', 'clinician', 'viewer'] as $preferredRole) {
            $role = $this->roles->firstWhere('slug', $preferredRole);

            if ($role instanceof Role) {
                return $role;
            }
        }

        /** @var Role|null $role */
        $role = $this->roles->first();

        return $role;
    }

    public function primaryRoleSlug(): string
    {
        return $this->primaryRole()?->slug
            ?? ($this->getAttribute('role') ?: config('rbac.default_role', 'clinician'));
    }

    /**
     * @param  string|array<int, string>|Role  $roles
     */
    public function hasRole(string|array|Role $roles): bool
    {
        $needles = collect($roles instanceof Role ? [$roles->slug] : (array) $roles)
            ->filter()
            ->map(static fn (string $role): string => strtolower($role))
            ->values();

        if ($needles->isEmpty()) {
            return false;
        }

        $this->loadMissing('roles');

        $currentRoles = $this->roles
            ->flatMap(fn (Role $role) => [$role->slug, $role->name])
            ->filter()
            ->map(static fn (string $role): string => strtolower($role));

        return $needles->contains(fn (string $needle) => $currentRoles->contains($needle));
    }

    /**
     * @param  string|array<int, string>  $permissions
     */
    public function hasPermissionTo(string|array $permissions): bool
    {
        if ($this->hasRole('admin')) {
            return true;
        }

        $needles = collect((array) $permissions)
            ->filter()
            ->map(static fn (string $permission): string => strtolower($permission))
            ->values();

        if ($needles->isEmpty()) {
            return false;
        }

        $availablePermissions = $this->permissions()
            ->map(fn (Permission $permission) => strtolower($permission->slug))
            ->values();

        return $needles->contains(
            fn (string $permission) => $availablePermissions->contains($permission),
        );
    }

    public function canAccessClinicalApi(): bool
    {
        return $this->hasPermissionTo('clinical-api.access');
    }

    /**
     * @return list<string>
     */
    public function tokenAbilities(): array
    {
        if ($this->hasRole('admin')) {
            return ['*'];
        }

        return $this->permissions()
            ->map(fn (Permission $permission) => $permission->slug)
            ->filter()
            ->unique()
            ->values()
            ->all();
    }

    /**
     * @param  string|Role  $role
     */
    public function assignRole(string|Role $role): static
    {
        $roleModel = $role instanceof Role
            ? $role
            : Role::query()->where('slug', $role)->orWhere('name', $role)->firstOrFail();

        $this->roles()->syncWithoutDetaching([$roleModel->id]);
        $this->syncLegacyRoleAttribute();

        return $this;
    }

    /**
     * @param  string|Role|array<int, string|Role>  $roles
     */
    public function syncRoles(string|Role|array $roles): static
    {
        $roleIds = collect((array) $roles)
            ->filter()
            ->map(function (string|Role $role): int {
                if ($role instanceof Role) {
                    return $role->id;
                }

                return (int) Role::query()
                    ->where('slug', $role)
                    ->orWhere('name', $role)
                    ->value('id');
            })
            ->filter()
            ->unique()
            ->values()
            ->all();

        $this->roles()->sync($roleIds);
        $this->unsetRelation('roles');
        $this->syncLegacyRoleAttribute();

        return $this;
    }

    protected function syncLegacyRoleAttribute(): void
    {
        $role = $this->primaryRole()?->slug ?? config('rbac.default_role', 'clinician');

        if ($this->getAttribute('role') === $role) {
            return;
        }

        $this->forceFill(['role' => $role])->saveQuietly();
    }
}
