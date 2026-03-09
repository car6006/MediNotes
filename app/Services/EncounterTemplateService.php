<?php

namespace App\Services;

use App\Models\EncounterTemplate;
use App\Models\User;
use App\Repositories\EncounterTemplateRepository;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class EncounterTemplateService
{
    public function __construct(
        private readonly EncounterTemplateRepository $templates,
    ) {
    }

    /**
     * @param  array<string, mixed>  $filters
     * @return Collection<int, EncounterTemplate>
     */
    public function list(User $actor, array $filters = []): Collection
    {
        return $this->templates->listForUser($actor, $filters);
    }

    public function detail(User $actor, EncounterTemplate $template): EncounterTemplate
    {
        return $this->templates->detailForUser($actor, $template->getKey());
    }

    public function resolve(User $actor, ?string $templateId, ?string $clinicId = null): ?EncounterTemplate
    {
        if (blank($templateId)) {
            return $this->templates->defaultForUser($actor, $clinicId);
        }

        return $this->templates->detailForUser($actor, (string) $templateId);
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function create(User $actor, array $payload): EncounterTemplate
    {
        return DB::transaction(function () use ($actor, $payload): EncounterTemplate {
            $title = trim((string) $payload['title']);
            $sections = $this->normalizeTemplateSections($payload);
            $template = $this->templates->create([
                'id' => $payload['id'] ?? (string) Str::uuid(),
                'clinic_id' => $this->resolveClinicId($actor, $payload['clinic_id'] ?? null),
                'title' => $title,
                'slug' => $this->normalizedString($payload['slug'] ?? null) ?? Str::slug($title),
                'version' => $this->normalizedString($payload['version'] ?? null) ?? '1.0',
                'specialty' => $this->normalizedString($payload['specialty'] ?? null),
                'note_format' => $this->normalizedString($payload['note_format'] ?? null) ?? 'soap',
                'template_body' => trim((string) $payload['template_body']),
                'instructions' => $this->normalizedString($payload['instructions'] ?? null),
                'sections' => $this->legacySectionsPayload($sections),
                'is_system' => $actor->hasRole('admin')
                    ? (bool) ($payload['is_system'] ?? false)
                    : false,
                'is_active' => (bool) ($payload['is_active'] ?? true),
                'created_by' => $this->resolveAuthorId($actor, $payload['created_by'] ?? null),
            ]);

            $this->syncSections($template, $sections);

            return $this->detail($actor, $template);
        });
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function update(User $actor, EncounterTemplate $template, array $payload): EncounterTemplate
    {
        return DB::transaction(function () use ($actor, $template, $payload): EncounterTemplate {
            $current = $this->detail($actor, $template);
            $sections = array_key_exists('encounter_sections', $payload) || array_key_exists('sections', $payload)
                ? $this->normalizeTemplateSections($payload)
                : null;
            $title = array_key_exists('title', $payload)
                ? trim((string) $payload['title'])
                : $current->title;

            $attributes = [];

            if (array_key_exists('clinic_id', $payload)) {
                $attributes['clinic_id'] = $this->resolveClinicId($actor, $payload['clinic_id']);
            }

            if (array_key_exists('title', $payload)) {
                $attributes['title'] = $title;
            }

            if (array_key_exists('slug', $payload)) {
                $attributes['slug'] = $this->normalizedString($payload['slug']) ?? Str::slug($title);
            }

            if (array_key_exists('version', $payload)) {
                $attributes['version'] = $this->normalizedString($payload['version']) ?? '1.0';
            }

            if (array_key_exists('specialty', $payload)) {
                $attributes['specialty'] = $this->normalizedString($payload['specialty']);
            }

            if (array_key_exists('note_format', $payload)) {
                $attributes['note_format'] = $this->normalizedString($payload['note_format']) ?? 'soap';
            }

            if (array_key_exists('template_body', $payload)) {
                $attributes['template_body'] = trim((string) $payload['template_body']);
            }

            if (array_key_exists('instructions', $payload)) {
                $attributes['instructions'] = $this->normalizedString($payload['instructions']);
            }

            if ($sections !== null) {
                $attributes['sections'] = $this->legacySectionsPayload($sections);
            }

            if (array_key_exists('is_system', $payload) && $actor->hasRole('admin')) {
                $attributes['is_system'] = (bool) $payload['is_system'];
            }

            if (array_key_exists('is_active', $payload)) {
                $attributes['is_active'] = (bool) $payload['is_active'];
            }

            $updated = $this->templates->update($current, $attributes);

            if ($sections !== null) {
                $this->syncSections($updated, $sections);
            }

            return $this->detail($actor, $updated);
        });
    }

    /**
     * @return list<array<string, mixed>>
     */
    public function sectionBlueprints(?EncounterTemplate $template): array
    {
        if ($template?->relationLoaded('encounterSections') && $template->encounterSections->isNotEmpty()) {
            return $template->encounterSections
                ->sortBy('position')
                ->map(fn ($section): array => [
                    'key' => $section->key,
                    'label' => $section->label,
                    'position' => $section->position,
                    'prompt' => $section->prompt,
                    'is_required' => $section->is_required,
                    'content' => $section->default_content,
                ])
                ->values()
                ->all();
        }

        if (is_array($template?->sections) && $template->sections !== []) {
            return collect($template->sections)
                ->values()
                ->map(function (mixed $section, int $index): array {
                    if (is_string($section)) {
                        return [
                            'key' => strtolower(str_replace(' ', '_', trim($section))),
                            'label' => trim($section),
                            'position' => $index + 1,
                            'prompt' => null,
                            'is_required' => false,
                            'content' => null,
                        ];
                    }

                    $payload = is_array($section) ? $section : [];
                    $label = (string) ($payload['label'] ?? $payload['key'] ?? 'Section');
                    $key = (string) ($payload['key'] ?? strtolower(str_replace(' ', '_', $label)));

                    return [
                        'key' => $key,
                        'label' => $payload['label'] ?? ucfirst(str_replace('_', ' ', $key)),
                        'position' => (int) ($payload['position'] ?? ($index + 1)),
                        'prompt' => $payload['prompt'] ?? null,
                        'is_required' => (bool) ($payload['is_required'] ?? false),
                        'content' => $payload['content'] ?? null,
                    ];
                })
                ->all();
        }

        return [
            [
                'key' => 'subjective',
                'label' => 'Subjective',
                'position' => 1,
                'prompt' => 'Capture symptoms, concerns, and patient narrative.',
                'is_required' => true,
                'content' => null,
            ],
            [
                'key' => 'objective',
                'label' => 'Objective',
                'position' => 2,
                'prompt' => 'Document findings, observations, and measurements.',
                'is_required' => true,
                'content' => null,
            ],
            [
                'key' => 'assessment',
                'label' => 'Assessment',
                'position' => 3,
                'prompt' => 'Summarise the working diagnosis and clinical impression.',
                'is_required' => true,
                'content' => null,
            ],
            [
                'key' => 'plan',
                'label' => 'Plan',
                'position' => 4,
                'prompt' => 'Record treatment, investigations, and follow-up actions.',
                'is_required' => true,
                'content' => null,
            ],
        ];
    }

    private function resolveClinicId(User $actor, ?string $requestedClinicId): ?string
    {
        $actor->loadMissing('providerProfile');

        if ($actor->hasRole('admin')) {
            return $requestedClinicId;
        }

        return $actor->providerProfile?->clinic_id ?? $requestedClinicId;
    }

    private function resolveAuthorId(User $actor, mixed $requestedAuthorId): int
    {
        if (! $actor->hasRole('admin')) {
            return $actor->id;
        }

        return is_numeric($requestedAuthorId) ? (int) $requestedAuthorId : $actor->id;
    }

    /**
     * @param  array<string, mixed>  $payload
     * @return list<array<string, mixed>>
     */
    private function normalizeTemplateSections(array $payload): array
    {
        $sections = Arr::wrap($payload['encounter_sections'] ?? $payload['sections'] ?? []);

        return collect($sections)
            ->values()
            ->map(function (mixed $section, int $index): array {
                if (is_string($section)) {
                    $label = trim($section);

                    return [
                        'id' => (string) Str::uuid(),
                        'key' => Str::slug($label, '_'),
                        'label' => $label,
                        'position' => $index + 1,
                        'prompt' => null,
                        'is_required' => false,
                        'default_content' => null,
                        'meta' => null,
                    ];
                }

                $payload = is_array($section) ? $section : [];
                $label = trim((string) ($payload['label'] ?? $payload['key'] ?? 'Section'));
                $key = trim((string) ($payload['key'] ?? Str::slug($label, '_')));

                return [
                    'id' => $payload['id'] ?? (string) Str::uuid(),
                    'key' => $key,
                    'label' => $label,
                    'position' => (int) ($payload['position'] ?? ($index + 1)),
                    'prompt' => $this->normalizedString($payload['prompt'] ?? null),
                    'is_required' => (bool) ($payload['is_required'] ?? false),
                    'default_content' => $this->normalizedString($payload['default_content'] ?? $payload['content'] ?? null),
                    'meta' => is_array($payload['meta'] ?? null) ? $payload['meta'] : null,
                ];
            })
            ->filter(fn (array $section): bool => $section['key'] !== '' && $section['label'] !== '')
            ->sortBy('position')
            ->values()
            ->all();
    }

    /**
     * @param  list<array<string, mixed>>  $sections
     * @return list<string>
     */
    private function legacySectionsPayload(array $sections): array
    {
        return array_values(array_map(
            static fn (array $section): string => (string) $section['label'],
            $sections,
        ));
    }

    /**
     * @param  list<array<string, mixed>>  $sections
     */
    private function syncSections(EncounterTemplate $template, array $sections): void
    {
        $template->encounterSections()->delete();

        if ($sections === []) {
            return;
        }

        $template->encounterSections()->createMany($sections);
    }

    private function normalizedString(mixed $value): ?string
    {
        if (! is_string($value)) {
            return $value;
        }

        $trimmed = trim($value);

        return $trimmed === '' ? null : $trimmed;
    }
}