<?php

namespace App\Http\Requests\Templates;

use Illuminate\Foundation\Http\FormRequest;

class UpdateEncounterTemplateRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'clinic_id' => ['sometimes', 'nullable', 'uuid', 'exists:clinics,id'],
            'title' => ['sometimes', 'required', 'string', 'max:255'],
            'slug' => ['sometimes', 'nullable', 'string', 'max:255'],
            'version' => ['sometimes', 'nullable', 'string', 'max:32'],
            'specialty' => ['sometimes', 'nullable', 'string', 'max:255'],
            'note_format' => ['sometimes', 'nullable', 'string', 'max:32'],
            'template_body' => ['sometimes', 'required', 'string'],
            'instructions' => ['sometimes', 'nullable', 'string'],
            'is_system' => ['sometimes', 'boolean'],
            'is_active' => ['sometimes', 'boolean'],
            'sections' => ['sometimes', 'nullable', 'array'],
            'encounter_sections' => ['sometimes', 'nullable', 'array'],
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
