<?php

namespace App\Services;

use App\Enums\EncounterStatus;
use App\Enums\TranscriptType;
use App\Models\AudioFile;
use App\Models\Encounter;
use App\Models\Transcript;
use App\Models\User;
use App\Repositories\EncounterRepository;
use App\Repositories\TranscriptRepository;
use App\Support\EncounterStateMachine;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class TranscriptService
{
    public function __construct(
        private readonly EncounterRepository $encounters,
        private readonly TranscriptRepository $transcripts,
        private readonly EncounterStateMachine $stateMachine,
    ) {
    }

    /**
     * @return Collection<int, Transcript>
     */
    public function list(User $actor, Encounter $encounter): Collection
    {
        $current = $this->encounters->detailForUser($actor, $encounter);

        return $this->transcripts->forEncounter($current);
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function store(User $actor, Encounter $encounter, array $payload): Transcript
    {
        $current = $this->encounters->detailForUser($actor, $encounter);
        $type = TranscriptType::from((string) $payload['transcript_type']);
        $audioFile = $this->resolveAudioFile($current, $payload['audio_file_id'] ?? null);

        $this->ensureAiConsent($current);

        $transcript = $this->transcripts->create([
            'id' => $payload['id'] ?? (string) Str::uuid(),
            'encounter_id' => $current->id,
            'audio_file_id' => $audioFile?->id,
            'transcript_type' => $type->value,
            'source_engine' => $this->normalizedString($payload['source_engine'] ?? ($type === TranscriptType::RAW ? 'offline_whisper' : 'manual_review')),
            'content' => trim((string) $payload['content']),
            'language' => $this->normalizedString($payload['language'] ?? null),
            'confidence' => $payload['confidence'] ?? null,
            'generated_by_user_id' => $actor->id,
            'reviewed_by_user_id' => $type === TranscriptType::CLEANED ? $actor->id : null,
            'reviewed_at' => $type === TranscriptType::CLEANED ? now() : null,
            'meta' => $payload['meta'] ?? null,
        ]);

        $transitionAttributes = $this->stateMachine->progress($current, EncounterStatus::TRANSCRIPTION_PENDING);
        $compatibilityAttributes = $type === TranscriptType::CLEANED
            ? ['transcript' => $transcript->content]
            : [];

        if ($transitionAttributes !== [] || $compatibilityAttributes !== []) {
            $this->encounters->update($current, [...$transitionAttributes, ...$compatibilityAttributes]);
        }

        return $transcript->load(['audioFile', 'generatedBy', 'reviewedBy']);
    }

    public function latestForEncounter(Encounter $encounter, TranscriptType $type): ?Transcript
    {
        return $this->transcripts->latestForEncounter($encounter, $type);
    }

    private function resolveAudioFile(Encounter $encounter, ?string $audioFileId): ?AudioFile
    {
        if (blank($audioFileId)) {
            return null;
        }

        $audioFile = AudioFile::query()->findOrFail($audioFileId);

        if ($audioFile->encounter_id !== $encounter->id) {
            throw ValidationException::withMessages([
                'audio_file_id' => 'The selected audio file does not belong to the encounter.',
            ]);
        }

        return $audioFile;
    }

    private function ensureAiConsent(Encounter $encounter): void
    {
        if (! config('clinical.dictation.require_ai_consent', true)) {
            return;
        }

        if ($encounter->ai_transcription_consent_obtained_at === null) {
            throw ValidationException::withMessages([
                'ai_transcription_consent_obtained_at' => 'AI transcription consent is required before storing encounter transcripts.',
            ]);
        }
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