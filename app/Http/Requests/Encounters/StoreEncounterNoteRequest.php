<?php

namespace App\Http\Requests\Encounters;

use App\Enums\ClinicalNoteStatus;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreEncounterNoteRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'id' => ['sometimes', 'uuid'],
            'status' => ['sometimes', Rule::in([
                ClinicalNoteStatus::DRAFT->value,
                ClinicalNoteStatus::REVIEW_PENDING->value,
            ])],
            'generate_with_medicai' => ['nullable', 'boolean'],
            'change_summary' => ['nullable', 'string', 'max:1000'],
            'sections' => ['nullable', 'array'],
            'sections.*.key' => ['nullable', 'string', 'max:64'],
            'sections.*.label' => ['nullable', 'string', 'max:255'],
            'sections.*.position' => ['nullable', 'integer', 'min:1'],
            'sections.*.prompt' => ['nullable', 'string'],
            'sections.*.is_required' => ['nullable', 'boolean'],
            'sections.*.content' => ['nullable', 'string'],
            'meta' => ['nullable', 'array'],
        ];
    }
}
