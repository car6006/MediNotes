<?php

namespace App\Http\Requests\Notes;

use Illuminate\Foundation\Http\FormRequest;

class SignClinicalNoteRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'signature_statement' => ['nullable', 'string', 'max:1000'],
            'meta' => ['nullable', 'array'],
        ];
    }
}
