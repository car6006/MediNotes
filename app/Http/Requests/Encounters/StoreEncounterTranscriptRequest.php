<?php

namespace App\Http\Requests\Encounters;

use App\Enums\TranscriptType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreEncounterTranscriptRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'id' => ['sometimes', 'uuid'],
            'audio_file_id' => ['nullable', 'uuid', 'exists:audio_files,id'],
            'transcript_type' => ['required', Rule::in(TranscriptType::values())],
            'source_engine' => ['nullable', 'string', 'max:64'],
            'content' => ['required', 'string'],
            'language' => ['nullable', 'string', 'max:16'],
            'confidence' => ['nullable', 'numeric', 'between:0,100'],
            'meta' => ['nullable', 'array'],
        ];
    }
}
