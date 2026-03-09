<?php

namespace App\Enums;

enum TranscriptType: string
{
    case RAW = 'raw';
    case CLEANED = 'cleaned';

    /**
     * @return list<string>
     */
    public static function values(): array
    {
        return array_map(
            static fn (self $type): string => $type->value,
            self::cases(),
        );
    }
}