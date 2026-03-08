<?php

namespace App\Http\Requests\Patients;

class StorePatientRequest extends PatientUpsertRequest
{
    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return $this->patientRules();
    }
}
