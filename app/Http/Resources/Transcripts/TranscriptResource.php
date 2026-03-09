<?php

namespace App\Http\Resources\Transcripts;

use App\Models\Transcript;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Transcript */
class TranscriptResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'encounter_id' => $this->encounter_id,
            'audio_file_id' => $this->audio_file_id,
            'transcript_type' => $this->transcript_type,
            'source_engine' => $this->source_engine,
            'content' => $this->content,
            'language' => $this->language,
            'confidence' => $this->confidence !== null ? (float) $this->confidence : null,
            'reviewed_at' => $this->reviewed_at?->toIso8601String(),
            'meta' => $this->meta ?? [],
            'audio_file' => $this->audioFile ? [
                'id' => $this->audioFile->id,
                'original_filename' => $this->audioFile->original_filename,
                'capture_mode' => $this->audioFile->capture_mode,
                'captured_at' => $this->audioFile->captured_at?->toIso8601String(),
            ] : null,
            'generated_by' => $this->generatedBy ? [
                'id' => $this->generatedBy->id,
                'name' => $this->generatedBy->name,
                'email' => $this->generatedBy->email,
            ] : null,
            'reviewed_by' => $this->reviewedBy ? [
                'id' => $this->reviewedBy->id,
                'name' => $this->reviewedBy->name,
                'email' => $this->reviewedBy->email,
            ] : null,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
