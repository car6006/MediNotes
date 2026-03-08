<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Dictation extends Model
{
    /** @use HasFactory<\Database\Factories\DictationFactory> */
    use HasFactory, HasUuids;

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'visit_id',
        'mode',
        'status',
        'locale',
        'audio_path',
        'transcript',
        'summary',
        'processed_offline',
        'duration_seconds',
        'meta',
    ];

    protected function casts(): array
    {
        return [
            'processed_offline' => 'boolean',
            'duration_seconds' => 'integer',
            'meta' => 'array',
        ];
    }

    public function visit(): BelongsTo
    {
        return $this->belongsTo(Visit::class);
    }
}
