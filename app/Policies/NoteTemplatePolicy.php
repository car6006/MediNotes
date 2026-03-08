<?php

namespace App\Policies;

use App\Models\NoteTemplate;
use App\Models\User;

class NoteTemplatePolicy
{
    public function viewAny(User $user): bool
    {
        return $user->hasPermissionTo('templates.read');
    }

    public function view(User $user, NoteTemplate $template): bool
    {
        return $user->hasPermissionTo('templates.read');
    }

    public function create(User $user): bool
    {
        return $user->hasPermissionTo('templates.write');
    }

    public function update(User $user, NoteTemplate $template): bool
    {
        return $user->hasPermissionTo('templates.write');
    }
}
