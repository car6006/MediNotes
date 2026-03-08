<?php

namespace App\Http\Requests\Appointments;

class UpdateAppointmentRequest extends AppointmentUpsertRequest
{
    public function rules(): array
    {
        return $this->appointmentRules(true);
    }
}
