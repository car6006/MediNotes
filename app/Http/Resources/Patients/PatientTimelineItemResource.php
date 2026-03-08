<?php

namespace App\Http\Resources\Patients;

use App\Models\Visit;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Str;

/** @mixin Visit */
class PatientTimelineItemResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'encounter_type' => $this->encounter_type,
            'status' => $this->status,
            'chief_complaint' => $this->chief_complaint,
            'summary' => $this->conversation_summary
                ?? $this->assessment
                ?? Str::limit($this->patient_update ?? $this->plan, 140),
            'template' => $this->template ? [
                'id' => $this->template->id,
                'title' => $this->template->title,
                'specialty' => $this->template->specialty,
            ] : null,
            'dictations_count' => $this->dictations_count,
            'started_at' => $this->started_at?->toIso8601String(),
            'completed_at' => $this->completed_at?->toIso8601String(),
            'synced_at' => $this->synced_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
