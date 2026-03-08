<?php

namespace App\Policies;

use App\Models\OnboardingForm;
use App\Models\User;

class OnboardingFormPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->hasPermissionTo('onboarding.read');
    }

    public function view(User $user, OnboardingForm $form): bool
    {
        return $user->hasPermissionTo('onboarding.read');
    }
}
