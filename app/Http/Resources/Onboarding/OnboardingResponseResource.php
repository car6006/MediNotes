<?php

namespace App\Http\Resources\Onboarding;

use App\Models\OnboardingResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin OnboardingResponse */
class OnboardingResponseResource extends JsonResource
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
            'onboarding_form_id' => $this->onboarding_form_id,
            'submitted_by_user_id' => $this->submitted_by_user_id,
            'source_channel' => $this->source_channel,
            'responses' => $this->responses ?? [],
            'submitted_at' => $this->submitted_at?->toIso8601String(),
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
            'form' => $this->form ? [
                'id' => $this->form->id,
                'title' => $this->form->title,
                'slug' => $this->form->slug,
                'version' => $this->form->version,
            ] : null,
            'submitted_by' => $this->submittedBy ? [
                'id' => $this->submittedBy->id,
                'name' => $this->submittedBy->name,
                'email' => $this->submittedBy->email,
            ] : null,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
