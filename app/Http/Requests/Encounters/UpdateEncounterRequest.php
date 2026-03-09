<?php

namespace App\Http\Requests\Encounters;

use App\Enums\EncounterStatus;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateEncounterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'provider_id' => ['sometimes', 'nullable', 'uuid', 'exists:providers,id'],
            'encounter_template_id' => ['sometimes', 'nullable', 'uuid', 'exists:note_templates,id'],
            'encounter_type' => ['sometimes', 'nullable', 'string', 'max:255'],
            'status' => ['sometimes', Rule::in([
                EncounterStatus::IN_PROGRESS->value,
                EncounterStatus::COMPLETED->value,
            ])],
            'chief_complaint' => ['sometimes', 'nullable', 'string'],
            'patient_update' => ['sometimes', 'nullable', 'string'],
            'privacy_notice_acknowledged_at' => ['sometimes', 'nullable', 'date'],
            'recording_consent_obtained_at' => ['sometimes', 'nullable', 'date'],
            'recording_consent_method' => ['sometimes', 'nullable', 'string', 'max:255'],
            'ai_transcription_consent_obtained_at' => ['sometimes', 'nullable', 'date'],
            'consent_notes' => ['sometimes', 'nullable', 'string'],
            'meta' => ['sometimes', 'nullable', 'array'],
            'started_at' => ['sometimes', 'nullable', 'date'],
        ];
    }
}
