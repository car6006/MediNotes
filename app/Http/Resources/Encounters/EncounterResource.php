<?php

namespace App\Http\Resources\Encounters;

use App\Http\Resources\Audio\AudioFileResource;
use App\Http\Resources\Notes\ClinicalNoteResource;
use App\Http\Resources\Transcripts\TranscriptResource;
use App\Models\Encounter;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Encounter */
class EncounterResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            ...(new EncounterSummaryResource($this->resource))->toArray($request),
            'clinic' => $this->clinic ? [
                'id' => $this->clinic->id,
                'name' => $this->clinic->name,
                'slug' => $this->clinic->slug,
            ] : null,
            'clinician' => $this->clinician ? [
                'id' => $this->clinician->id,
                'name' => $this->clinician->name,
                'email' => $this->clinician->email,
            ] : null,
            'patient' => $this->patient ? [
                'id' => $this->patient->id,
                'medical_record_number' => $this->patient->medical_record_number,
                'full_name' => $this->patient->full_name,
                'preferred_name' => $this->patient->preferred_name,
                'phone' => $this->patient->phone,
                'email' => $this->patient->email,
                'has_alerts' => $this->patient->has_alerts,
                'alerts' => $this->patient->alerts ?? [],
            ] : null,
            'encounter_template' => $this->template ? [
                'id' => $this->template->id,
                'title' => $this->template->title,
                'version' => $this->template->version,
                'specialty' => $this->template->specialty,
                'note_format' => $this->template->note_format,
                'sections' => $this->template->sections ?? [],
            ] : null,
            'compatibility_note' => [
                'conversation_summary' => $this->conversation_summary,
                'subjective' => $this->subjective,
                'objective' => $this->objective,
                'assessment' => $this->assessment,
                'plan' => $this->plan,
                'patient_update' => $this->patient_update,
                'transcript' => $this->transcript,
            ],
            'template_snapshot' => $this->template_snapshot,
            'meta' => $this->meta ?? [],
            'audio_files' => $this->relationLoaded('audioFiles') ? AudioFileResource::collection($this->audioFiles) : [],
            'transcripts' => $this->relationLoaded('transcripts') ? TranscriptResource::collection($this->transcripts) : [],
            'current_clinical_note' => $this->currentClinicalNote ? new ClinicalNoteResource($this->currentClinicalNote) : null,
        ];
    }
}
