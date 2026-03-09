<?php

namespace App\Http\Requests\Encounters;

use Illuminate\Foundation\Http\FormRequest;

class StoreEncounterAudioRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'id' => ['sometimes', 'uuid'],
            'storage_disk' => ['nullable', 'string', 'max:64'],
            'storage_path' => ['required', 'string', 'max:2048'],
            'original_filename' => ['nullable', 'string', 'max:255'],
            'mime_type' => ['nullable', 'string', 'max:128'],
            'file_size_bytes' => ['nullable', 'integer', 'min:1'],
            'duration_seconds' => ['nullable', 'integer', 'min:0'],
            'checksum_sha256' => ['nullable', 'string', 'size:64'],
            'capture_mode' => ['nullable', 'string', 'max:64'],
            'captured_at' => ['nullable', 'date'],
            'meta' => ['nullable', 'array'],
        ];
    }
}
