<?php

namespace App\Http\Requests\Templates;

use Illuminate\Foundation\Http\FormRequest;

class ListEncounterTemplatesRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'clinic_id' => ['nullable', 'uuid', 'exists:clinics,id'],
            'specialty' => ['nullable', 'string', 'max:255'],
            'active' => ['nullable', 'boolean'],
        ];
    }
}
