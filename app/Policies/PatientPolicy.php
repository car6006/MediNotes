<?php

namespace App\Policies;

use App\Models\Patient;
use App\Models\User;

class PatientPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->hasPermissionTo('patients.read');
    }

    public function view(User $user, Patient $patient): bool
    {
        return $user->hasPermissionTo('patients.read');
    }

    public function create(User $user): bool
    {
        return $user->hasPermissionTo('patients.write');
    }

    public function update(User $user, Patient $patient): bool
    {
        return $user->hasPermissionTo('patients.write');
    }
}
