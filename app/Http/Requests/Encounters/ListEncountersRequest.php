<?php

namespace App\Http\Requests\Encounters;

use App\Enums\EncounterStatus;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ListEncountersRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'clinic_id' => ['nullable', 'uuid', 'exists:clinics,id'],
            'patient_id' => ['nullable', 'uuid', 'exists:patients,id'],
            'appointment_id' => ['nullable', 'uuid', 'exists:appointments,id'],
            'provider_id' => ['nullable', 'uuid', 'exists:providers,id'],
            'status' => ['nullable', Rule::in(EncounterStatus::values())],
            'date' => ['nullable', 'date'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
        ];
    }
}
