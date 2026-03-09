<?php

namespace App\Http\Resources\Notes;

use App\Models\ClinicalNote;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin ClinicalNote */
class ClinicalNoteResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'encounter_id' => $this->encounter_id,
            'status' => $this->status,
            'note_format' => $this->note_format,
            'current_version_id' => $this->current_version_id,
            'current_version_number' => $this->current_version_number,
            'meta' => $this->meta ?? [],
            'encounter' => $this->encounter ? [
                'id' => $this->encounter->id,
                'patient_id' => $this->encounter->patient_id,
                'status' => $this->encounter->status,
                'chief_complaint' => $this->encounter->chief_complaint,
            ] : null,
            'created_by' => $this->createdBy ? [
                'id' => $this->createdBy->id,
                'name' => $this->createdBy->name,
                'email' => $this->createdBy->email,
            ] : null,
            'signed_by' => $this->signedBy ? [
                'id' => $this->signedBy->id,
                'name' => $this->signedBy->name,
                'email' => $this->signedBy->email,
            ] : null,
            'signed_at' => $this->signed_at?->toIso8601String(),
            'current_version' => $this->currentVersion ? new ClinicalNoteVersionResource($this->currentVersion) : null,
            'versions' => $this->relationLoaded('versions') ? ClinicalNoteVersionResource::collection($this->versions) : null,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
