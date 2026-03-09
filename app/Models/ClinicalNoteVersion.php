<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ClinicalNoteVersion extends Model
{
    use HasFactory, HasUuids;

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'clinical_note_id',
        'encounter_id',
        'version_number',
        'source',
        'sections_json',
        'raw_transcript_id',
        'cleaned_transcript_id',
        'generated_by_user_id',
        'signed_by_user_id',
        'signed_at',
        'is_locked',
        'change_summary',
        'meta',
    ];

    protected function casts(): array
    {
        return [
            'sections_json' => 'array',
            'signed_at' => 'datetime',
            'is_locked' => 'boolean',
            'meta' => 'array',
        ];
    }

    public function clinicalNote(): BelongsTo
    {
        return $this->belongsTo(ClinicalNote::class);
    }

    public function encounter(): BelongsTo
    {
        return $this->belongsTo(Encounter::class);
    }

    public function rawTranscript(): BelongsTo
    {
        return $this->belongsTo(Transcript::class, 'raw_transcript_id');
    }

    public function cleanedTranscript(): BelongsTo
    {
        return $this->belongsTo(Transcript::class, 'cleaned_transcript_id');
    }

    public function generatedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'generated_by_user_id');
    }

    public function signedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'signed_by_user_id');
    }
}