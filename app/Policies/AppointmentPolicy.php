<?php

namespace App\Policies;

use App\Models\Appointment;
use App\Models\User;

class AppointmentPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->hasPermissionTo('appointments.read');
    }

    public function view(User $user, Appointment $appointment): bool
    {
        return $user->hasPermissionTo('appointments.read');
    }

    public function create(User $user): bool
    {
        return $user->hasPermissionTo('appointments.write');
    }

    public function update(User $user, Appointment $appointment): bool
    {
        return $user->hasPermissionTo('appointments.write');
    }
}
