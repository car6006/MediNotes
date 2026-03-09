<?php

namespace App\Enums;

enum EncounterStatus: string
{
    case CREATED = 'created';
    case IN_PROGRESS = 'in_progress';
    case DICTATION_CAPTURED = 'dictation_captured';
    case TRANSCRIPTION_PENDING = 'transcription_pending';
    case DRAFT_NOTE_READY = 'draft_note_ready';
    case DOCTOR_REVIEW_PENDING = 'doctor_review_pending';
    case SIGNED_OFF = 'signed_off';
    case COMPLETED = 'completed';

    /**
     * @return list<string>
     */
    public static function values(): array
    {
        return array_map(
            static fn (self $status): string => $status->value,
            self::cases(),
        );
    }

    /**
     * @return list<self>
     */
    public static function ordered(): array
    {
        return [
            self::CREATED,
            self::IN_PROGRESS,
            self::DICTATION_CAPTURED,
            self::TRANSCRIPTION_PENDING,
            self::DRAFT_NOTE_READY,
            self::DOCTOR_REVIEW_PENDING,
            self::SIGNED_OFF,
            self::COMPLETED,
        ];
    }

    public function order(): int
    {
        foreach (self::ordered() as $index => $status) {
            if ($status === $this) {
                return $index;
            }
        }

        return 0;
    }

    public function isAtLeast(self $other): bool
    {
        return $this->order() >= $other->order();
    }

    public function timestampColumn(): ?string
    {
        return match ($this) {
            self::CREATED => null,
            self::IN_PROGRESS => 'in_progress_at',
            self::DICTATION_CAPTURED => 'dictation_captured_at',
            self::TRANSCRIPTION_PENDING => 'transcription_pending_at',
            self::DRAFT_NOTE_READY => 'draft_note_ready_at',
            self::DOCTOR_REVIEW_PENDING => 'doctor_review_pending_at',
            self::SIGNED_OFF => 'signed_off_at',
            self::COMPLETED => 'completed_at',
        };
    }
}