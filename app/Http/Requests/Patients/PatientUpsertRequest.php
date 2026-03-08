<?php

namespace App\Http\Requests\Patients;

use App\Models\Patient;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

abstract class PatientUpsertRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    protected function patientRules(bool $updating = false): array
    {
        $patient = $this->route('patient');
        $patientId = $patient instanceof Patient
            ? $patient->id
            : ($this->route('patientId') ?: null);
        $requiredNameRule = $updating ? ['sometimes', 'required', 'string', 'max:255'] : ['required', 'string', 'max:255'];

        return [
            'id' => ['sometimes', 'uuid'],
            'clinic_id' => ['nullable', 'uuid', 'exists:clinics,id'],
            'medical_record_number' => [
                'nullable',
                'string',
                'max:255',
                Rule::unique('patients', 'medical_record_number')->ignore($patientId),
            ],
            'title' => ['nullable', 'string', 'max:32'],
            'first_name' => $requiredNameRule,
            'middle_name' => ['nullable', 'string', 'max:255'],
            'last_name' => $requiredNameRule,
            'preferred_name' => ['nullable', 'string', 'max:255'],
            'date_of_birth' => ['nullable', 'date'],
            'sex' => ['nullable', 'string', 'max:32'],
            'phone' => ['nullable', 'string', 'max:255'],
            'alternate_phone' => ['nullable', 'string', 'max:255'],
            'email' => ['nullable', 'email', 'max:255'],
            'national_id_number' => [
                'nullable',
                'string',
                'max:255',
                Rule::unique('patients', 'national_id_number')->ignore($patientId),
            ],
            'passport_number' => [
                'nullable',
                'string',
                'max:255',
                Rule::unique('patients', 'passport_number')->ignore($patientId),
            ],
            'external_reference' => [
                'nullable',
                'string',
                'max:255',
                Rule::unique('patients', 'external_reference')->ignore($patientId),
            ],
            'address_line_1' => ['nullable', 'string', 'max:255'],
            'address_line_2' => ['nullable', 'string', 'max:255'],
            'city' => ['nullable', 'string', 'max:255'],
            'province' => ['nullable', 'string', 'max:255'],
            'postal_code' => ['nullable', 'string', 'max:32'],
            'country' => ['nullable', 'string', 'size:2'],
            'emergency_contact_name' => ['nullable', 'string', 'max:255'],
            'emergency_contact_phone' => ['nullable', 'string', 'max:255'],
            'allergies' => ['nullable', 'array'],
            'allergies.*' => ['string', 'max:255'],
            'allergies_summary' => ['nullable', 'string'],
            'medications' => ['nullable', 'array'],
            'medications.*' => ['string', 'max:255'],
            'medication_summary' => ['nullable', 'string'],
            'medical_history' => ['nullable', 'array'],
            'medical_history.*' => ['string', 'max:500'],
            'medical_history_summary' => ['nullable', 'string'],
            'alerts' => ['nullable', 'array'],
            'alerts.*' => ['string', 'max:255'],
            'notes' => ['nullable', 'string'],
            'last_visit_at' => ['nullable', 'date'],
        ];
    }
}
