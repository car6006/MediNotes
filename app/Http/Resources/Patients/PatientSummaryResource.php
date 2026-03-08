<?php

namespace App\Http\Resources\Patients;

use App\Models\Patient;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Patient */
class PatientSummaryResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $visitsCount = $this->resource->getAttribute('visits_count')
            ?? ($this->relationLoaded('visits') ? $this->visits->count() : 0);

        return [
            'id' => $this->id,
            'clinic_id' => $this->clinic_id,
            'medical_record_number' => $this->medical_record_number,
            'full_name' => $this->full_name,
            'preferred_name' => $this->preferred_name,
            'date_of_birth' => $this->date_of_birth?->toDateString(),
            'sex' => $this->sex,
            'phone' => $this->phone,
            'email' => $this->email,
            'medical_history_summary' => $this->medical_history_summary ?: $this->summaryPlaceholder($this->medical_history, 'Medical history summary pending capture.'),
            'allergies_summary' => $this->allergies_summary ?: $this->summaryPlaceholder($this->allergies, 'Allergy summary pending capture.'),
            'medication_summary' => $this->medication_summary ?: $this->summaryPlaceholder($this->medications, 'Medication summary pending capture.'),
            'clinic' => $this->clinic ? [
                'id' => $this->clinic->id,
                'name' => $this->clinic->name,
                'slug' => $this->clinic->slug,
            ] : null,
            'identifiers' => [
                'medical_record_number' => $this->medical_record_number,
                'national_id_number' => $this->national_id_number,
                'passport_number' => $this->passport_number,
                'external_reference' => $this->external_reference,
            ],
            'demographics' => [
                'date_of_birth' => $this->date_of_birth?->toDateString(),
                'age' => $this->date_of_birth?->age,
                'sex' => $this->sex,
            ],
            'contact' => [
                'phone' => $this->phone,
                'alternate_phone' => $this->alternate_phone,
                'email' => $this->email,
            ],
            'summaries' => [
                'medical_history' => $this->medical_history_summary ?: $this->summaryPlaceholder($this->medical_history, 'Medical history summary pending capture.'),
                'allergies' => $this->allergies_summary ?: $this->summaryPlaceholder($this->allergies, 'Allergy summary pending capture.'),
                'medications' => $this->medication_summary ?: $this->summaryPlaceholder($this->medications, 'Medication summary pending capture.'),
            ],
            'alerts' => $this->alerts ?? [],
            'has_alerts' => (bool) $this->has_alerts,
            'last_visit_at' => $this->last_visit_at?->toIso8601String(),
            'visits_count' => $visitsCount,
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }

    /**
     * @param  array<int, string>|null  $items
     */
    private function summaryPlaceholder(?array $items, string $fallback): string
    {
        $items = array_values(array_filter($items ?? []));

        return $items === [] ? $fallback : implode('; ', $items);
    }
}
