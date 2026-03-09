<?php

namespace App\Support;

use App\Enums\EncounterStatus;
use App\Models\Encounter;
use Illuminate\Validation\ValidationException;

class EncounterStateMachine
{
    /**
     * @var array<string, list<string>>
     */
    private const TRANSITIONS = [
        'created' => ['in_progress'],
        'in_progress' => ['dictation_captured'],
        'dictation_captured' => ['transcription_pending'],
        'transcription_pending' => ['draft_note_ready', 'in_progress'],
        'draft_note_ready' => ['doctor_review_pending', 'in_progress'],
        'doctor_review_pending' => ['signed_off', 'draft_note_ready'],
        'signed_off' => ['completed', 'doctor_review_pending'],
        'completed' => [],
    ];

    /**
     * @return array<string, mixed>
     */
    public function transition(Encounter $encounter, EncounterStatus $target): array
    {
        $current = EncounterStatus::from((string) $encounter->status);

        if ($current === $target) {
            return [];
        }

        if (! $this->canTransition($current, $target)) {
            throw ValidationException::withMessages([
                'status' => sprintf('Encounter cannot transition from %s to %s.', $current->value, $target->value),
            ]);
        }

        return $this->applyTimestamps($encounter, $target, now());
    }

    /**
     * @return array<string, mixed>
     */
    public function progress(Encounter $encounter, EncounterStatus $target): array
    {
        $current = EncounterStatus::from((string) $encounter->status);

        if ($current->isAtLeast($target)) {
            return [];
        }

        $ordered = EncounterStatus::ordered();
        $now = now();
        $attributes = [];

        for ($index = $current->order() + 1; $index <= $target->order(); $index++) {
            $previous = $ordered[$index - 1];
            $step = $ordered[$index];

            if (! $this->canTransition($previous, $step)) {
                throw ValidationException::withMessages([
                    'status' => sprintf('Encounter cannot progress from %s to %s.', $previous->value, $step->value),
                ]);
            }

            $attributes = $this->applyTimestamps($encounter, $step, $now, $attributes);
        }

        return $attributes;
    }

    private function canTransition(EncounterStatus $from, EncounterStatus $to): bool
    {
        return in_array($to->value, self::TRANSITIONS[$from->value] ?? [], true);
    }

    /**
     * @param  array<string, mixed>  $attributes
     * @return array<string, mixed>
     */
    private function applyTimestamps(Encounter $encounter, EncounterStatus $status, mixed $now, array $attributes = []): array
    {
        $attributes['status'] = $status->value;
        $attributes['status_changed_at'] = $now;

        if ($status === EncounterStatus::IN_PROGRESS && ! array_key_exists('started_at', $attributes) && $encounter->started_at === null) {
            $attributes['started_at'] = $now;
        }

        $timestampColumn = $status->timestampColumn();

        if ($timestampColumn !== null && ! array_key_exists($timestampColumn, $attributes) && $encounter->{$timestampColumn} === null) {
            $attributes[$timestampColumn] = $now;
        }

        return $attributes;
    }
}