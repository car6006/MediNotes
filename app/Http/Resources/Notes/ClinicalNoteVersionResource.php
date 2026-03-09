<?php

namespace App\Http\Resources\Notes;

use App\Models\ClinicalNoteVersion;
use App\Http\Resources\Transcripts\TranscriptResource;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin ClinicalNoteVersion */
class ClinicalNoteVersionResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'clinical_note_id' => $this->clinical_note_id,
            'encounter_id' => $this->encounter_id,
            'version_number' => $this->version_number,
            'source' => $this->source,
            'sections' => $this->sections_json ?? [],
            'raw_transcript_id' => $this->raw_transcript_id,
            'cleaned_transcript_id' => $this->cleaned_transcript_id,
            'raw_transcript' => $this->rawTranscript ? new TranscriptResource($this->rawTranscript) : null,
            'cleaned_transcript' => $this->cleanedTranscript ? new TranscriptResource($this->cleanedTranscript) : null,
            'generated_by' => $this->generatedBy ? [
                'id' => $this->generatedBy->id,
                'name' => $this->generatedBy->name,
                'email' => $this->generatedBy->email,
            ] : null,
            'signed_by' => $this->signedBy ? [
                'id' => $this->signedBy->id,
                'name' => $this->signedBy->name,
                'email' => $this->signedBy->email,
            ] : null,
            'signed_at' => $this->signed_at?->toIso8601String(),
            'is_locked' => $this->is_locked,
            'change_summary' => $this->change_summary,
            'meta' => $this->meta ?? [],
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
