<?php

namespace App\Policies;

use App\Models\OnboardingResponse;
use App\Models\User;

class OnboardingResponsePolicy
{
    public function viewAny(User $user): bool
    {
        return $user->hasPermissionTo('onboarding.read');
    }

    public function view(User $user, OnboardingResponse $response): bool
    {
        return $user->hasPermissionTo('onboarding.read');
    }

    public function create(User $user): bool
    {
        return $user->hasPermissionTo('onboarding.write');
    }
}
