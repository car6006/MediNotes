<?php

namespace App\Enums;

enum ClinicalNoteStatus: string
{
    case DRAFT = 'draft';
    case REVIEW_PENDING = 'doctor_review_pending';
    case SIGNED_OFF = 'signed_off';

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
}