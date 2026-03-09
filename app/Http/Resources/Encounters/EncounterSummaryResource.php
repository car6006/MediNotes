<?php

namespace App\Http\Resources\Encounters;

use App\Models\Encounter;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Encounter */
class EncounterSummaryResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $audioCount = $this->resource->getAttribute('audio_files_count')
            ?? ($this->relationLoaded('audioFiles') ? $this->audioFiles->count() : 0);
        $transcriptCount = $this->resource->getAttribute('transcripts_count')
            ?? ($this->relationLoaded('transcripts') ? $this->transcripts->count() : 0);

        return [
            'id' => $this->id,
            'clinic_id' => $this->clinic_id,
            'patient_id' => $this->patient_id,
            'appointment_id' => $this->appointment_id,
            'provider_id' => $this->provider_id,
            'clinician_id' => $this->clinician_id,
            'encounter_template_id' => $this->encounter_template_id,
            'encounter_type' => $this->encounter_type,
            'status' => $this->status,
            'chief_complaint' => $this->chief_complaint,
            'patient' => $this->patient ? [
                'id' => $this->patient->id,
                'medical_record_number' => $this->patient->medical_record_number,
                'full_name' => $this->patient->full_name,
                'preferred_name' => $this->patient->preferred_name,
            ] : null,
            'provider' => $this->provider ? [
                'id' => $this->provider->id,
                'full_name' => $this->provider->full_name,
                'specialty' => $this->provider->specialty,
            ] : null,
            'appointment' => $this->appointment ? [
                'id' => $this->appointment->id,
                'status' => $this->appointment->status,
                'scheduled_for' => $this->appointment->scheduled_for?->toIso8601String(),
            ] : null,
            'encounter_template' => $this->template ? [
                'id' => $this->template->id,
                'title' => $this->template->title,
                'version' => $this->template->version,
                'note_format' => $this->template->note_format,
            ] : null,
            'counts' => [
                'audio_files' => $audioCount,
                'transcripts' => $transcriptCount,
            ],
            'current_clinical_note' => $this->currentClinicalNote ? [
                'id' => $this->currentClinicalNote->id,
                'status' => $this->currentClinicalNote->status,
                'current_version_number' => $this->currentClinicalNote->current_version_number,
                'signed_at' => $this->currentClinicalNote->signed_at?->toIso8601String(),
            ] : null,
            'consent' => [
                'privacy_notice_acknowledged_at' => $this->privacy_notice_acknowledged_at?->toIso8601String(),
                'recording_consent_obtained_at' => $this->recording_consent_obtained_at?->toIso8601String(),
                'recording_consent_method' => $this->recording_consent_method,
                'ai_transcription_consent_obtained_at' => $this->ai_transcription_consent_obtained_at?->toIso8601String(),
                'consent_notes' => $this->consent_notes,
            ],
            'timeline' => [
                'status_changed_at' => $this->status_changed_at?->toIso8601String(),
                'started_at' => $this->started_at?->toIso8601String(),
                'in_progress_at' => $this->in_progress_at?->toIso8601String(),
                'dictation_captured_at' => $this->dictation_captured_at?->toIso8601String(),
                'transcription_pending_at' => $this->transcription_pending_at?->toIso8601String(),
                'draft_note_ready_at' => $this->draft_note_ready_at?->toIso8601String(),
                'doctor_review_pending_at' => $this->doctor_review_pending_at?->toIso8601String(),
                'signed_off_at' => $this->signed_off_at?->toIso8601String(),
                'completed_at' => $this->completed_at?->toIso8601String(),
                'synced_at' => $this->synced_at?->toIso8601String(),
            ],
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
