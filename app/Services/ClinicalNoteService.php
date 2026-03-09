<?php

namespace App\Services;

use App\Enums\ClinicalNoteStatus;
use App\Enums\EncounterStatus;
use App\Enums\TranscriptType;
use App\Models\ClinicalNote;
use App\Models\ClinicalNoteVersion;
use App\Models\Encounter;
use App\Models\User;
use App\Repositories\ClinicalNoteRepository;
use App\Repositories\EncounterRepository;
use App\Support\EncounterStateMachine;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Arr;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class ClinicalNoteService
{
    public function __construct(
        private readonly EncounterRepository $encounters,
        private readonly ClinicalNoteRepository $notes,
        private readonly TranscriptService $transcripts,
        private readonly EncounterTemplateService $templates,
        private readonly MedicAIService $medicAI,
        private readonly EncounterStateMachine $stateMachine,
    ) {
    }

    public function detail(User $actor, ClinicalNote $note): ClinicalNote
    {
        $current = $this->notes->detail($note);
        $this->encounters->detailForUser($actor, $current->encounter);

        return $current;
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function createDraft(User $actor, Encounter $encounter, array $payload): ClinicalNote
    {
        $current = $this->encounters->detailForUser($actor, $encounter);

        if ($current->currentClinicalNote !== null || $current->clinicalNote !== null) {
            throw ValidationException::withMessages([
                'encounter_id' => 'A clinical note already exists for this encounter.',
            ]);
        }

        $template = $this->templates->resolve($actor, $current->encounter_template_id, $current->clinic_id);
        $rawTranscript = $this->transcripts->latestForEncounter($current, TranscriptType::RAW);
        $cleanedTranscript = $this->transcripts->latestForEncounter($current, TranscriptType::CLEANED);
        $requestedStatus = isset($payload['status'])
            ? ClinicalNoteStatus::from((string) $payload['status'])
            : ClinicalNoteStatus::DRAFT;

        if ($requestedStatus === ClinicalNoteStatus::SIGNED_OFF) {
            throw ValidationException::withMessages([
                'status' => 'Clinical notes must be signed off via the dedicated sign endpoint.',
            ]);
        }

        $sectionBlueprints = $this->templates->sectionBlueprints($template);
        $medicAISections = ($payload['generate_with_medicai'] ?? true)
            ? $this->medicAI->suggestSoapSections([
                'encounter_id' => $current->id,
                'chief_complaint' => $current->chief_complaint,
                'raw_transcript' => $rawTranscript?->content,
                'cleaned_transcript' => $cleanedTranscript?->content,
                'template' => $template?->only(['id', 'title', 'version', 'note_format']),
            ])
            : ['ok' => true, 'sections' => []];
        $structuredNote = ($payload['generate_with_medicai'] ?? true)
            ? $this->medicAI->generateStructuredNote([
                'encounter_id' => $current->id,
                'chief_complaint' => $current->chief_complaint,
                'raw_transcript' => $rawTranscript?->content,
                'cleaned_transcript' => $cleanedTranscript?->content,
                'template' => $template?->only(['id', 'title', 'version', 'note_format']),
            ])
            : ['ok' => true, 'payload' => []];
        $safetyFlags = $this->medicAI->flagSafetyConcerns([
            'encounter_id' => $current->id,
            'chief_complaint' => $current->chief_complaint,
            'raw_transcript' => $rawTranscript?->content,
            'cleaned_transcript' => $cleanedTranscript?->content,
        ]);

        $sections = $this->normalizeSections(
            inputSections: Arr::wrap($payload['sections'] ?? []),
            blueprints: $sectionBlueprints,
            fallbackContent: $cleanedTranscript?->content,
            aiSections: Arr::wrap($medicAISections['sections'] ?? []),
        );

        $note = $this->notes->create([
            'id' => $payload['id'] ?? (string) Str::uuid(),
            'encounter_id' => $current->id,
            'current_version_number' => 1,
            'status' => $requestedStatus->value,
            'note_format' => $template?->note_format ?? 'soap',
            'created_by_user_id' => $actor->id,
            'meta' => [
                'medicai' => [
                    'draft' => $structuredNote,
                    'sections' => $medicAISections,
                    'safety' => $safetyFlags,
                ],
            ],
        ]);

        $version = $this->notes->createVersion([
            'id' => (string) Str::uuid(),
            'clinical_note_id' => $note->id,
            'encounter_id' => $current->id,
            'version_number' => 1,
            'source' => ($payload['generate_with_medicai'] ?? true) ? 'medicai_draft' : 'manual_seed',
            'sections_json' => $sections,
            'raw_transcript_id' => $rawTranscript?->id,
            'cleaned_transcript_id' => $cleanedTranscript?->id,
            'generated_by_user_id' => $actor->id,
            'is_locked' => false,
            'change_summary' => $this->normalizedString($payload['change_summary'] ?? 'Initial draft created.'),
            'meta' => [
                'medicai' => [
                    'draft' => $structuredNote,
                    'sections' => $medicAISections,
                    'safety' => $safetyFlags,
                ],
            ],
        ]);

        $this->notes->update($note, [
            'current_version_id' => $version->id,
            'current_version_number' => 1,
        ]);

        $encounterAttributes = [
            'current_clinical_note_id' => $note->id,
            ...$this->compatibilityFieldsFromSections($sections),
        ];

        $targetStatus = $requestedStatus === ClinicalNoteStatus::REVIEW_PENDING
            ? EncounterStatus::DOCTOR_REVIEW_PENDING
            : EncounterStatus::DRAFT_NOTE_READY;

        $this->encounters->update($current, [
            ...$encounterAttributes,
            ...$this->stateMachine->progress($current, $targetStatus),
        ]);

        return $this->notes->detail($note);
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function update(User $actor, ClinicalNote $note, array $payload): ClinicalNote
    {
        $current = $this->notes->detail($note);
        $encounter = $this->encounters->detailForUser($actor, $current->encounter);
        $currentVersion = $current->currentVersion;

        if (! $currentVersion instanceof ClinicalNoteVersion) {
            throw ValidationException::withMessages([
                'note' => 'The current clinical note version could not be resolved.',
            ]);
        }

        $requestedStatus = $this->resolveUpdatedStatus($current, $payload);
        $sections = $this->normalizeSections(
            inputSections: Arr::wrap($payload['sections'] ?? $currentVersion->sections_json ?? []),
            blueprints: $this->templates->sectionBlueprints($encounter->encounterTemplate),
            fallbackContent: $currentVersion->cleanedTranscript?->content,
            aiSections: [],
        );
        $nextVersionNumber = (int) $current->current_version_number + 1;
        $source = $current->status === ClinicalNoteStatus::SIGNED_OFF->value
            ? 'post_sign_revision'
            : 'manual_edit';

        $version = $this->notes->createVersion([
            'id' => (string) Str::uuid(),
            'clinical_note_id' => $current->id,
            'encounter_id' => $encounter->id,
            'version_number' => $nextVersionNumber,
            'source' => $source,
            'sections_json' => $sections,
            'raw_transcript_id' => $currentVersion->raw_transcript_id,
            'cleaned_transcript_id' => $currentVersion->cleaned_transcript_id,
            'generated_by_user_id' => $actor->id,
            'is_locked' => false,
            'change_summary' => $this->normalizedString($payload['change_summary'] ?? 'Clinical note revised.'),
            'meta' => $payload['meta'] ?? $currentVersion->meta,
        ]);

        $this->notes->update($current, [
            'current_version_id' => $version->id,
            'current_version_number' => $nextVersionNumber,
            'status' => $requestedStatus->value,
            'signed_by_user_id' => $requestedStatus === ClinicalNoteStatus::SIGNED_OFF ? $current->signed_by_user_id : null,
            'signed_at' => $requestedStatus === ClinicalNoteStatus::SIGNED_OFF ? $current->signed_at : null,
            'meta' => $payload['meta'] ?? $current->meta,
        ]);

        $encounterStatusTarget = $requestedStatus === ClinicalNoteStatus::REVIEW_PENDING
            ? EncounterStatus::DOCTOR_REVIEW_PENDING
            : EncounterStatus::DRAFT_NOTE_READY;
        $transitionAttributes = $encounter->status === EncounterStatus::SIGNED_OFF->value
            ? $this->stateMachine->transition($encounter, EncounterStatus::DOCTOR_REVIEW_PENDING)
            : ($requestedStatus === ClinicalNoteStatus::REVIEW_PENDING
                ? $this->stateMachine->progress($encounter, EncounterStatus::DOCTOR_REVIEW_PENDING)
                : $this->draftReadyAttributes($encounter));

        $this->encounters->update($encounter, [
            ...$transitionAttributes,
            ...$this->compatibilityFieldsFromSections($sections),
        ]);

        return $this->notes->detail($current);
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function sign(User $actor, ClinicalNote $note, array $payload): ClinicalNote
    {
        $current = $this->notes->detail($note);

        if ($current->status !== ClinicalNoteStatus::REVIEW_PENDING->value) {
            throw ValidationException::withMessages([
                'status' => 'Only review-pending clinical notes can be signed off.',
            ]);
        }

        $currentVersion = $current->currentVersion;

        if (! $currentVersion instanceof ClinicalNoteVersion) {
            throw ValidationException::withMessages([
                'note' => 'The current clinical note version could not be resolved.',
            ]);
        }

        $currentVersion->fill([
            'signed_by_user_id' => $actor->id,
            'signed_at' => now(),
            'is_locked' => true,
            'change_summary' => $this->normalizedString($payload['signature_statement'] ?? $currentVersion->change_summary),
            'meta' => $payload['meta'] ?? $currentVersion->meta,
        ]);
        $currentVersion->save();

        $this->notes->update($current, [
            'status' => ClinicalNoteStatus::SIGNED_OFF->value,
            'signed_by_user_id' => $actor->id,
            'signed_at' => $currentVersion->signed_at,
            'meta' => $payload['meta'] ?? $current->meta,
        ]);

        $encounter = $this->encounters->detailForUser($actor, $current->encounter);
        $transitionAttributes = $encounter->status === EncounterStatus::DOCTOR_REVIEW_PENDING->value
            ? $this->stateMachine->transition($encounter, EncounterStatus::SIGNED_OFF)
            : $this->stateMachine->progress($encounter, EncounterStatus::SIGNED_OFF);

        $this->encounters->update($encounter, $transitionAttributes);

        return $this->notes->detail($current);
    }

    /**
     * @return Collection<int, ClinicalNoteVersion>
     */
    public function versions(User $actor, ClinicalNote $note): Collection
    {
        $current = $this->detail($actor, $note);

        return $this->notes->versions($current);
    }

    /**
     * @param  list<array<string, mixed>>  $inputSections
     * @param  list<array<string, mixed>>  $blueprints
     * @param  list<array<string, mixed>>  $aiSections
     * @return list<array<string, mixed>>
     */
    private function normalizeSections(array $inputSections, array $blueprints, ?string $fallbackContent = null, array $aiSections = []): array
    {
        $requested = collect($inputSections)
            ->filter(fn (mixed $section): bool => is_array($section))
            ->mapWithKeys(fn (array $section): array => [
                (string) ($section['key'] ?? Str::slug((string) ($section['label'] ?? 'section'), '_')) => $section,
            ]);
        $suggested = collect($aiSections)
            ->filter(fn (mixed $section): bool => is_array($section))
            ->mapWithKeys(fn (array $section): array => [
                (string) ($section['key'] ?? Str::slug((string) ($section['label'] ?? 'section'), '_')) => $section,
            ]);

        $sections = collect($blueprints)
            ->map(function (array $blueprint) use ($requested, $suggested, $fallbackContent): array {
                $key = (string) $blueprint['key'];
                $requestedSection = $requested->get($key, []);
                $suggestedSection = $suggested->get($key, []);

                return [
                    'key' => $key,
                    'label' => $requestedSection['label'] ?? $blueprint['label'],
                    'position' => (int) ($requestedSection['position'] ?? $blueprint['position']),
                    'prompt' => $requestedSection['prompt'] ?? $blueprint['prompt'] ?? null,
                    'is_required' => (bool) ($requestedSection['is_required'] ?? $blueprint['is_required'] ?? false),
                    'content' => $this->normalizedString($requestedSection['content'] ?? $suggestedSection['content'] ?? $blueprint['content'] ?? null)
                        ?? ($key === 'subjective' ? $fallbackContent : null),
                ];
            })
            ->values();

        $extras = $requested
            ->reject(fn (array $section, string $key): bool => collect($blueprints)->contains(fn (array $blueprint): bool => $blueprint['key'] === $key))
            ->values()
            ->map(fn (array $section): array => [
                'key' => $section['key'] ?? Str::slug((string) ($section['label'] ?? 'section'), '_'),
                'label' => $section['label'] ?? ucfirst((string) ($section['key'] ?? 'Section')),
                'position' => (int) ($section['position'] ?? ($sections->count() + 1)),
                'prompt' => $section['prompt'] ?? null,
                'is_required' => (bool) ($section['is_required'] ?? false),
                'content' => $this->normalizedString($section['content'] ?? null),
            ]);

        return $sections
            ->concat($extras)
            ->sortBy('position')
            ->values()
            ->all();
    }

    /**
     * @param  list<array<string, mixed>>  $sections
     * @return array<string, mixed>
     */
    private function compatibilityFieldsFromSections(array $sections): array
    {
        $content = collect($sections)
            ->mapWithKeys(fn (array $section): array => [$section['key'] => $this->normalizedString($section['content'] ?? null)]);

        return [
            'subjective' => $content->get('subjective'),
            'objective' => $content->get('objective'),
            'assessment' => $content->get('assessment'),
            'plan' => $content->get('plan'),
            'conversation_summary' => collect($sections)
                ->map(fn (array $section): string => trim(sprintf('%s: %s', $section['label'], (string) ($section['content'] ?? ''))))
                ->filter()
                ->implode("\n"),
        ];
    }

    private function resolveUpdatedStatus(ClinicalNote $current, array $payload): ClinicalNoteStatus
    {
        if (array_key_exists('status', $payload)) {
            $requested = ClinicalNoteStatus::from((string) $payload['status']);

            if ($requested === ClinicalNoteStatus::SIGNED_OFF) {
                throw ValidationException::withMessages([
                    'status' => 'Clinical notes must be signed off via the dedicated sign endpoint.',
                ]);
            }

            return $requested;
        }

        if ($current->status === ClinicalNoteStatus::SIGNED_OFF->value) {
            return ClinicalNoteStatus::REVIEW_PENDING;
        }

        return ClinicalNoteStatus::DRAFT;
    }

    /**
     * @return array<string, mixed>
     */
    private function draftReadyAttributes(Encounter $encounter): array
    {
        if ($encounter->status === EncounterStatus::SIGNED_OFF->value) {
            return $this->stateMachine->transition($encounter, EncounterStatus::DOCTOR_REVIEW_PENDING);
        }

        if ($encounter->status === EncounterStatus::DOCTOR_REVIEW_PENDING->value) {
            return $this->stateMachine->transition($encounter, EncounterStatus::DRAFT_NOTE_READY);
        }

        return $this->stateMachine->progress($encounter, EncounterStatus::DRAFT_NOTE_READY);
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