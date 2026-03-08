<?php

namespace App\Http\Requests\Patients;

use App\Models\Patient;

class UpdatePatientRequest extends PatientUpsertRequest
{
    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        $patientExists = Patient::query()->whereKey((string) $this->route('patientId'))->exists();

        return $this->patientRules(updating: $patientExists);
    }
}
