<?php

namespace App\Http\Requests\Onboarding;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreOnboardingResponseRequest extends FormRequest
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
            'onboarding_form_id' => ['required', 'uuid', 'exists:onboarding_forms,id'],
            'source_channel' => ['sometimes', Rule::in(self::CHANNELS)],
            'responses' => ['required', 'array'],
            'submitted_at' => ['nullable', 'date'],
        ];
    }
}
