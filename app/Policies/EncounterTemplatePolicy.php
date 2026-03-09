<?php

namespace App\Policies;

use App\Models\EncounterTemplate;
use App\Models\User;

class EncounterTemplatePolicy
{
    public function viewAny(User $user): bool
    {
        return $this->allows($user, 'encounter-templates.read', 'templates.read');
    }

    public function view(User $user, EncounterTemplate $template): bool
    {
        return $this->allows($user, 'encounter-templates.read', 'templates.read');
    }

    public function create(User $user): bool
    {
        return $this->allows($user, 'encounter-templates.write', 'templates.write');
    }

    public function update(User $user, EncounterTemplate $template): bool
    {
        return $this->allows($user, 'encounter-templates.write', 'templates.write');
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