<?php

namespace App\Policies;

use App\Models\ClinicalNote;
use App\Models\User;

class ClinicalNotePolicy
{
    public function viewAny(User $user): bool
    {
        return $this->allows($user, 'clinical-notes.read', 'encounters.read', 'visits.read');
    }

    public function view(User $user, ClinicalNote $note): bool
    {
        return $this->allows($user, 'clinical-notes.read', 'encounters.read', 'visits.read');
    }

    public function create(User $user): bool
    {
        return $this->allows($user, 'clinical-notes.write', 'encounters.write', 'visits.write');
    }

    public function update(User $user, ClinicalNote $note): bool
    {
        return $this->allows($user, 'clinical-notes.write', 'encounters.write', 'visits.write');
    }

    public function sign(User $user, ClinicalNote $note): bool
    {
        return $this->allows($user, 'clinical-notes.sign', 'clinical-notes.write', 'encounters.write', 'visits.write');
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