<?php

namespace App\Http\Requests\Templates;

use Illuminate\Foundation\Http\FormRequest;

class StoreEncounterTemplateRequest extends FormRequest
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
            'title' => ['required', 'string', 'max:255'],
            'slug' => ['nullable', 'string', 'max:255'],
            'version' => ['nullable', 'string', 'max:32'],
            'specialty' => ['nullable', 'string', 'max:255'],
            'note_format' => ['nullable', 'string', 'max:32'],
            'template_body' => ['required', 'string'],
            'instructions' => ['nullable', 'string'],
            'is_system' => ['nullable', 'boolean'],
            'is_active' => ['nullable', 'boolean'],
            'created_by' => ['nullable', 'integer', 'exists:users,id'],
            'sections' => ['nullable', 'array'],
            'encounter_sections' => ['nullable', 'array'],
            'encounter_sections.*.id' => ['sometimes', 'uuid'],
            'encounter_sections.*.key' => ['nullable', 'string', 'max:64'],
            'encounter_sections.*.label' => ['nullable', 'string', 'max:255'],
            'encounter_sections.*.position' => ['nullable', 'integer', 'min:1'],
            'encounter_sections.*.prompt' => ['nullable', 'string'],
            'encounter_sections.*.is_required' => ['nullable', 'boolean'],
            'encounter_sections.*.default_content' => ['nullable', 'string'],
            'encounter_sections.*.content' => ['nullable', 'string'],
            'encounter_sections.*.meta' => ['nullable', 'array'],
        ];
    }
}
