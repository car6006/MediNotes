<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Visit extends Model
{
    /** @use HasFactory<\Database\Factories\VisitFactory> */
    use HasFactory, HasUuids;

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'patient_id',
        'clinician_id',
        'note_template_id',
        'encounter_type',
        'status',
        'chief_complaint',
        'conversation_summary',
        'subjective',
        'objective',
        'assessment',
        'plan',
        'patient_update',
        'transcript',
        'privacy_notice_acknowledged_at',
        'recording_consent_obtained_at',
        'recording_consent_method',
        'ai_transcription_consent_obtained_at',
        'consent_notes',
        'template_snapshot',
        'meta',
        'started_at',
        'completed_at',
        'synced_at',
    ];

    protected function casts(): array
    {
        return [
            'template_snapshot' => 'array',
            'meta' => 'array',
            'privacy_notice_acknowledged_at' => 'datetime',
            'recording_consent_obtained_at' => 'datetime',
            'ai_transcription_consent_obtained_at' => 'datetime',
            'started_at' => 'datetime',
            'completed_at' => 'datetime',
            'synced_at' => 'datetime',
        ];
    }

    public function patient(): BelongsTo
    {
        return $this->belongsTo(Patient::class);
    }

    public function clinician(): BelongsTo
    {
        return $this->belongsTo(User::class, 'clinician_id');
    }

    public function template(): BelongsTo
    {
        return $this->belongsTo(NoteTemplate::class, 'note_template_id');
    }

    public function dictations(): HasMany
    {
        return $this->hasMany(Dictation::class)->latest();
    }
}
