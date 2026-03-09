<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Transcript extends Model
{
    use HasFactory, HasUuids;

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'encounter_id',
        'audio_file_id',
        'transcript_type',
        'source_engine',
        'content',
        'language',
        'confidence',
        'generated_by_user_id',
        'reviewed_by_user_id',
        'reviewed_at',
        'meta',
    ];

    protected function casts(): array
    {
        return [
            'confidence' => 'decimal:2',
            'reviewed_at' => 'datetime',
            'meta' => 'array',
        ];
    }

    public function encounter(): BelongsTo
    {
        return $this->belongsTo(Encounter::class);
    }

    public function audioFile(): BelongsTo
    {
        return $this->belongsTo(AudioFile::class);
    }

    public function generatedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'generated_by_user_id');
    }

    public function reviewedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by_user_id');
    }
}