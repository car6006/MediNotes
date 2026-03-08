<?php

namespace App\Http\Resources\Appointments;

use App\Models\Appointment;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Appointment */
class AppointmentResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $onboardingCount = $this->resource->getAttribute('onboarding_responses_count')
            ?? ($this->relationLoaded('onboardingResponses') ? $this->onboardingResponses->count() : 0);
        $consentCount = $this->resource->getAttribute('consents_count')
            ?? ($this->relationLoaded('consents') ? $this->consents->count() : 0);

        return [
            'id' => $this->id,
            'clinic_id' => $this->clinic_id,
            'patient_id' => $this->patient_id,
            'provider_id' => $this->provider_id,
            'booked_by_user_id' => $this->booked_by_user_id,
            'booking_type' => $this->booking_type,
            'status' => $this->status,
            'scheduled_for' => $this->scheduled_for?->toIso8601String(),
            'duration_minutes' => $this->duration_minutes,
            'reason_for_visit' => $this->reason_for_visit,
            'notes' => $this->notes,
            'booking_channel' => $this->booking_channel,
            'cancellation_reason' => $this->cancellation_reason,
            'metadata' => $this->metadata ?? [],
            'timeline' => [
                'confirmed_at' => $this->confirmed_at?->toIso8601String(),
                'arrived_at' => $this->arrived_at?->toIso8601String(),
                'in_consult_at' => $this->in_consult_at?->toIso8601String(),
                'completed_at' => $this->completed_at?->toIso8601String(),
                'cancelled_at' => $this->cancelled_at?->toIso8601String(),
                'no_show_at' => $this->no_show_at?->toIso8601String(),
            ],
            'clinic' => $this->clinic ? [
                'id' => $this->clinic->id,
                'name' => $this->clinic->name,
                'slug' => $this->clinic->slug,
            ] : null,
            'patient' => $this->patient ? [
                'id' => $this->patient->id,
                'medical_record_number' => $this->patient->medical_record_number,
                'full_name' => $this->patient->full_name,
                'preferred_name' => $this->patient->preferred_name,
                'phone' => $this->patient->phone,
                'email' => $this->patient->email,
            ] : null,
            'provider' => $this->provider ? [
                'id' => $this->provider->id,
                'full_name' => $this->provider->full_name,
                'specialty' => $this->provider->specialty,
                'email' => $this->provider->email,
                'phone' => $this->provider->phone,
            ] : null,
            'booked_by' => $this->bookedBy ? [
                'id' => $this->bookedBy->id,
                'name' => $this->bookedBy->name,
                'email' => $this->bookedBy->email,
            ] : null,
            'onboarding_responses_count' => $onboardingCount,
            'consents_count' => $consentCount,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
