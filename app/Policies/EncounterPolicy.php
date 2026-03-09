<?php

namespace App\Policies;

use App\Models\Encounter;
use App\Models\User;

class EncounterPolicy
{
    public function viewAny(User $user): bool
    {
        return $this->allows($user, 'encounters.read', 'visits.read');
    }

    public function view(User $user, Encounter $encounter): bool
    {
        return $this->allows($user, 'encounters.read', 'visits.read');
    }

    public function create(User $user): bool
    {
        return $this->allows($user, 'encounters.write', 'visits.write');
    }

    public function update(User $user, Encounter $encounter): bool
    {
        return $this->allows($user, 'encounters.write', 'visits.write');
    }

    /**
     * @param  list<string>  ...$permissions
     */
    private function allows(User $user, string ...$permissions): bool
    {
        foreach ($permissions as $permission) {
            if ($user->hasPermissionTo($permission)) {
                return true;
            }
        }

        return false;
    }
}