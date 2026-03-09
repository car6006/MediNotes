<?php

namespace App\Http\Requests\Encounters;

use Illuminate\Foundation\Http\FormRequest;

class StoreEncounterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'id' => ['sometimes', 'uuid'],
            'clinic_id' => ['nullable', 'uuid', 'exists:clinics,id'],
            'patient_id' => ['nullable', 'uuid', 'exists:patients,id', 'required_without:appointment_id'],
            'appointment_id' => ['nullable', 'uuid', 'exists:appointments,id', 'required_without:patient_id'],
            'provider_id' => ['nullable', 'uuid', 'exists:providers,id'],
            'encounter_template_id' => ['nullable', 'uuid', 'exists:note_templates,id'],
            'encounter_type' => ['nullable', 'string', 'max:255'],
            'chief_complaint' => ['nullable', 'string'],
            'privacy_notice_acknowledged_at' => ['nullable', 'date'],
            'recording_consent_obtained_at' => ['nullable', 'date'],
            'recording_consent_method' => ['nullable', 'string', 'max:255'],
            'ai_transcription_consent_obtained_at' => ['nullable', 'date'],
            'consent_notes' => ['nullable', 'string'],
            'meta' => ['nullable', 'array'],
            'started_at' => ['nullable', 'date'],
        ];
    }
}
