<?php

namespace App\Http\Resources\Templates;

use App\Models\EncounterTemplate;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Str;

/** @mixin EncounterTemplate */
class EncounterTemplateResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $sections = $this->relationLoaded('encounterSections') && $this->encounterSections->isNotEmpty()
            ? $this->encounterSections->map(fn ($section): array => [
                'id' => $section->id,
                'key' => $section->key,
                'label' => $section->label,
                'position' => $section->position,
                'prompt' => $section->prompt,
                'is_required' => $section->is_required,
                'default_content' => $section->default_content,
                'meta' => $section->meta ?? [],
            ])->values()->all()
            : collect($this->sections ?? [])->values()->map(function (mixed $section, int $index): array {
                if (is_string($section)) {
                    return [
                        'id' => null,
                        'key' => Str::slug($section, '_'),
                        'label' => $section,
                        'position' => $index + 1,
                        'prompt' => null,
                        'is_required' => false,
                        'default_content' => null,
                        'meta' => [],
                    ];
                }

                $payload = is_array($section) ? $section : [];
                $label = (string) ($payload['label'] ?? $payload['key'] ?? 'Section');

                return [
                    'id' => $payload['id'] ?? null,
                    'key' => $payload['key'] ?? Str::slug($label, '_'),
                    'label' => $payload['label'] ?? $label,
                    'position' => (int) ($payload['position'] ?? ($index + 1)),
                    'prompt' => $payload['prompt'] ?? null,
                    'is_required' => (bool) ($payload['is_required'] ?? false),
                    'default_content' => $payload['default_content'] ?? $payload['content'] ?? null,
                    'meta' => $payload['meta'] ?? [],
                ];
            })->all();

        return [
            'id' => $this->id,
            'clinic_id' => $this->clinic_id,
            'title' => $this->title,
            'slug' => $this->slug,
            'version' => $this->version,
            'specialty' => $this->specialty,
            'note_format' => $this->note_format,
            'template_body' => $this->template_body,
            'instructions' => $this->instructions,
            'sections' => $this->sections ?? [],
            'encounter_sections' => $sections,
            'is_system' => $this->is_system,
            'is_active' => $this->is_active,
            'clinic' => $this->clinic ? [
                'id' => $this->clinic->id,
                'name' => $this->clinic->name,
                'slug' => $this->clinic->slug,
            ] : null,
            'author' => $this->author ? [
                'id' => $this->author->id,
                'name' => $this->author->name,
                'email' => $this->author->email,
            ] : null,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
