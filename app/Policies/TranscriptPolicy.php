<?php

namespace App\Policies;

use App\Models\Transcript;
use App\Models\User;

class TranscriptPolicy
{
    public function viewAny(User $user): bool
    {
        return $this->allows($user, 'transcripts.read', 'encounters.read', 'visits.read');
    }

    public function view(User $user, Transcript $transcript): bool
    {
        return $this->allows($user, 'transcripts.read', 'encounters.read', 'visits.read');
    }

    public function create(User $user): bool
    {
        return $this->allows($user, 'transcripts.write', 'dictations.write', 'encounters.write', 'visits.write');
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