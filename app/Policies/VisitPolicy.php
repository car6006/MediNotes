<?php

namespace App\Policies;

use App\Models\User;
use App\Models\Visit;

class VisitPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->hasPermissionTo('visits.read');
    }

    public function view(User $user, Visit $visit): bool
    {
        return $user->hasPermissionTo('visits.read');
    }

    public function create(User $user): bool
    {
        return $user->hasPermissionTo('visits.write');
    }

    public function update(User $user, Visit $visit): bool
    {
        return $user->hasPermissionTo('visits.write');
    }

    public function recordDictation(User $user, Visit $visit): bool
    {
        return $user->hasPermissionTo('dictations.write');
    }
}
