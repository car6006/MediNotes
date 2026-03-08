<?php

namespace App\Policies;

use App\Models\ConsentTemplate;
use App\Models\User;

class ConsentTemplatePolicy
{
    public function viewAny(User $user): bool
    {
        return $user->hasPermissionTo('consents.read');
    }

    public function view(User $user, ConsentTemplate $template): bool
    {
        return $user->hasPermissionTo('consents.read');
    }
}
