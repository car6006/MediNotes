<?php

namespace App\Policies;

use App\Models\AudioFile;
use App\Models\User;

class AudioFilePolicy
{
    public function viewAny(User $user): bool
    {
        return $this->allows($user, 'encounter-audio.read', 'encounters.read', 'visits.read');
    }

    public function view(User $user, AudioFile $audioFile): bool
    {
        return $this->allows($user, 'encounter-audio.read', 'encounters.read', 'visits.read');
    }

    public function create(User $user): bool
    {
        return $this->allows($user, 'encounter-audio.write', 'dictations.write', 'encounters.write', 'visits.write');
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