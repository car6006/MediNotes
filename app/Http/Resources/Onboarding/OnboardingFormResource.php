<?php

namespace App\Http\Resources\Onboarding;

use App\Models\OnboardingForm;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin OnboardingForm */
class OnboardingFormResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'clinic_id' => $this->clinic_id,
            'title' => $this->title,
            'slug' => $this->slug,
            'description' => $this->description,
            'version' => $this->version,
            'schema' => $this->schema ?? [],
            'is_active' => (bool) $this->is_active,
            'clinic' => $this->clinic ? [
                'id' => $this->clinic->id,
                'name' => $this->clinic->name,
                'slug' => $this->clinic->slug,
            ] : null,
            'created_by' => $this->creator ? [
                'id' => $this->creator->id,
                'name' => $this->creator->name,
                'email' => $this->creator->email,
            ] : null,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
