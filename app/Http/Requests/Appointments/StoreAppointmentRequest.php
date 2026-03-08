<?php

namespace App\Http\Requests\Appointments;

class StoreAppointmentRequest extends AppointmentUpsertRequest
{
    public function rules(): array
    {
        return $this->appointmentRules();
    }
}
