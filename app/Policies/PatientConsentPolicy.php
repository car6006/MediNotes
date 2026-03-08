<?php

namespace App\Policies;

use App\Models\PatientConsent;
use App\Models\User;

class PatientConsentPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->hasPermissionTo('consents.read');
    }

    public function view(User $user, PatientConsent $consent): bool
    {
        return $user->hasPermissionTo('consents.read');
    }

    public function create(User $user): bool
    {
        return $user->hasPermissionTo('consents.write');
    }
}
