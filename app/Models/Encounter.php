<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Encounter extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'visits';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'clinic_id',
        'patient_id',
        'appointment_id',
        'provider_id',
        'current_clinical_note_id',
        'clinician_id',
        'note_template_id',
        'encounter_template_id',
        'encounter_type',
        'status',
        'status_changed_at',
        'in_progress_at',
        'dictation_captured_at',
        'transcription_pending_at',
        'draft_note_ready_at',
        'doctor_review_pending_at',
        'signed_off_at',
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

    protected $appends = [
        'encounter_template_id',
    ];

    protected function casts(): array
    {
        return [
            'template_snapshot' => 'array',
            'meta' => 'array',
            'privacy_notice_acknowledged_at' => 'datetime',
            'recording_consent_obtained_at' => 'datetime',
            'ai_transcription_consent_obtained_at' => 'datetime',
            'status_changed_at' => 'datetime',
            'in_progress_at' => 'datetime',
            'dictation_captured_at' => 'datetime',
            'transcription_pending_at' => 'datetime',
            'draft_note_ready_at' => 'datetime',
            'doctor_review_pending_at' => 'datetime',
            'signed_off_at' => 'datetime',
            'started_at' => 'datetime',
            'completed_at' => 'datetime',
            'synced_at' => 'datetime',
        ];
    }

    public function clinic(): BelongsTo
    {
        return $this->belongsTo(Clinic::class);
    }

    public function appointment(): BelongsTo
    {
        return $this->belongsTo(Appointment::class);
    }

    public function patient(): BelongsTo
    {
        return $this->belongsTo(Patient::class);
    }

    public function provider(): BelongsTo
    {
        return $this->belongsTo(Provider::class);
    }

    public function clinician(): BelongsTo
    {
        return $this->belongsTo(User::class, 'clinician_id');
    }

    public function encounterTemplate(): BelongsTo
    {
        return $this->belongsTo(EncounterTemplate::class, 'note_template_id');
    }

    public function template(): BelongsTo
    {
        return $this->belongsTo(EncounterTemplate::class, 'note_template_id');
    }

    public function dictations(): HasMany
    {
        return $this->hasMany(Dictation::class, 'visit_id')->latest();
    }

    public function audioFiles(): HasMany
    {
        return $this->hasMany(AudioFile::class)->latest('captured_at');
    }

    public function transcripts(): HasMany
    {
        return $this->hasMany(Transcript::class)->latest();
    }

    public function clinicalNote(): HasOne
    {
        return $this->hasOne(ClinicalNote::class)->latestOfMany();
    }

    public function currentClinicalNote(): BelongsTo
    {
        return $this->belongsTo(ClinicalNote::class, 'current_clinical_note_id');
    }

    public function getEncounterTemplateIdAttribute(): ?string
    {
        return $this->attributes['note_template_id'] ?? null;
    }

    public function setEncounterTemplateIdAttribute(?string $value): void
    {
        $this->attributes['note_template_id'] = $value;
    }
}