<?php

namespace App\Http\Resources\Consents;

use App\Models\PatientConsent;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin PatientConsent */
class PatientConsentResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'clinic_id' => $this->clinic_id,
            'patient_id' => $this->patient_id,
            'appointment_id' => $this->appointment_id,
            'consent_template_id' => $this->consent_template_id,
            'captured_by_user_id' => $this->captured_by_user_id,
            'accepted_by' => $this->accepted_by,
            'source_channel' => $this->source_channel,
            'accepted_at' => $this->accepted_at?->toIso8601String(),
            'template_version' => $this->template_version,
            'template_snapshot' => $this->template_snapshot,
            'accepted_payload' => $this->accepted_payload,
            'notes' => $this->notes,
            'patient' => $this->patient ? [
                'id' => $this->patient->id,
                'full_name' => $this->patient->full_name,
                'medical_record_number' => $this->patient->medical_record_number,
            ] : null,
            'appointment' => $this->appointment ? [
                'id' => $this->appointment->id,
                'status' => $this->appointment->status,
                'scheduled_for' => $this->appointment->scheduled_for?->toIso8601String(),
            ] : null,
            'template' => $this->template ? [
                'id' => $this->template->id,
                'title' => $this->template->title,
                'slug' => $this->template->slug,
                'consent_type' => $this->template->consent_type,
                'version' => $this->template->version,
            ] : null,
            'captured_by' => $this->capturedBy ? [
                'id' => $this->capturedBy->id,
                'name' => $this->capturedBy->name,
                'email' => $this->capturedBy->email,
            ] : null,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
