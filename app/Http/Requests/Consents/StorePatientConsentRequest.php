<?php

namespace App\Http\Requests\Consents;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StorePatientConsentRequest extends FormRequest
{
    private const CHANNELS = [
        'in_person',
        'mobile',
        'web',
        'admin_capture',
    ];

    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'patient_id' => ['required', 'uuid', 'exists:patients,id'],
            'appointment_id' => ['nullable', 'uuid', 'exists:appointments,id'],
            'consent_template_id' => ['required', 'uuid', 'exists:consent_templates,id'],
            'accepted_by' => ['required', 'string', 'max:255'],
            'accepted_at' => ['nullable', 'date'],
            'source_channel' => ['sometimes', Rule::in(self::CHANNELS)],
            'accepted_payload' => ['nullable', 'array'],
            'notes' => ['nullable', 'string'],
        ];
    }
}
