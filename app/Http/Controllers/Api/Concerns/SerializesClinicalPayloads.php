<?php

namespace App\Http\Controllers\Api\Concerns;

use App\Models\Dictation;
use App\Models\NoteTemplate;
use App\Models\Patient;
use App\Models\Visit;

trait SerializesClinicalPayloads
{
    protected function patientData(Patient $patient, bool $includeVisits = false): array
    {
        $patient->loadMissing(['clinic', 'visits']);

        return [
            'id' => $patient->id,
            'clinic_id' => $patient->clinic_id,
            'clinic' => $patient->clinic ? [
                'id' => $patient->clinic->id,
                'name' => $patient->clinic->name,
                'slug' => $patient->clinic->slug,
            ] : null,
            'medical_record_number' => $patient->medical_record_number,
            'first_name' => $patient->first_name,
            'last_name' => $patient->last_name,
            'full_name' => $patient->full_name,
            'date_of_birth' => $patient->date_of_birth?->toDateString(),
            'sex' => $patient->sex,
            'phone' => $patient->phone,
            'email' => $patient->email,
            'national_id_number' => $patient->national_id_number,
            'passport_number' => $patient->passport_number,
            'external_reference' => $patient->external_reference,
            'medical_history_summary' => $patient->medical_history_summary,
            'allergies_summary' => $patient->allergies_summary,
            'medication_summary' => $patient->medication_summary,
            'allergies' => $patient->allergies ?? [],
            'medications' => $patient->medications ?? [],
            'medical_history' => $patient->medical_history ?? [],
            'notes' => $patient->notes,
            'alerts' => $patient->alerts ?? [],
            'has_alerts' => $patient->has_alerts,
            'last_visit_at' => $patient->last_visit_at?->toIso8601String(),
            'visits_count' => $patient->visits->count(),
            'visits' => $includeVisits
                ? $patient->visits->map(fn (Visit $visit) => $this->visitData($visit, includePatient: false, includeDictations: false))->values()->all()
                : null,
            'created_at' => $patient->created_at?->toIso8601String(),
            'updated_at' => $patient->updated_at?->toIso8601String(),
        ];
    }

    protected function visitData(Visit $visit, bool $includePatient = true, bool $includeDictations = true): array
    {
        if ($includePatient) {
            $visit->loadMissing('patient');
        }

        $visit->loadMissing('template');

        if ($includeDictations) {
            $visit->loadMissing('dictations');
        }

        return [
            'id' => $visit->id,
            'patient_id' => $visit->patient_id,
            'patient' => $includePatient && $visit->patient ? [
                'id' => $visit->patient->id,
                'full_name' => $visit->patient->full_name,
                'medical_record_number' => $visit->patient->medical_record_number,
            ] : null,
            'clinician_id' => $visit->clinician_id,
            'note_template_id' => $visit->note_template_id,
            'template' => $visit->template ? [
                'id' => $visit->template->id,
                'title' => $visit->template->title,
                'specialty' => $visit->template->specialty,
            ] : null,
            'encounter_type' => $visit->encounter_type,
            'status' => $visit->status,
            'chief_complaint' => $visit->chief_complaint,
            'conversation_summary' => $visit->conversation_summary,
            'subjective' => $visit->subjective,
            'objective' => $visit->objective,
            'assessment' => $visit->assessment,
            'plan' => $visit->plan,
            'patient_update' => $visit->patient_update,
            'transcript' => $visit->transcript,
            'consent' => [
                'privacy_notice_acknowledged_at' => $visit->privacy_notice_acknowledged_at?->toIso8601String(),
                'recording_consent_obtained_at' => $visit->recording_consent_obtained_at?->toIso8601String(),
                'recording_consent_method' => $visit->recording_consent_method,
                'ai_transcription_consent_obtained_at' => $visit->ai_transcription_consent_obtained_at?->toIso8601String(),
                'consent_notes' => $visit->consent_notes,
                'privacy_notice_version' => config('clinical.privacy_notice_version'),
            ],
            'template_snapshot' => $visit->template_snapshot,
            'meta' => $visit->meta,
            'dictations' => $includeDictations
                ? $visit->dictations->map(fn (Dictation $dictation) => $this->dictationData($dictation))->values()->all()
                : null,
            'started_at' => $visit->started_at?->toIso8601String(),
            'completed_at' => $visit->completed_at?->toIso8601String(),
            'synced_at' => $visit->synced_at?->toIso8601String(),
            'created_at' => $visit->created_at?->toIso8601String(),
            'updated_at' => $visit->updated_at?->toIso8601String(),
        ];
    }

    protected function templateData(NoteTemplate $template): array
    {
        return [
            'id' => $template->id,
            'title' => $template->title,
            'specialty' => $template->specialty,
            'template_body' => $template->template_body,
            'sections' => $template->sections ?? [],
            'is_system' => $template->is_system,
            'created_by' => $template->created_by,
            'created_at' => $template->created_at?->toIso8601String(),
            'updated_at' => $template->updated_at?->toIso8601String(),
        ];
    }

    protected function dictationData(Dictation $dictation): array
    {
        return [
            'id' => $dictation->id,
            'visit_id' => $dictation->visit_id,
            'mode' => $dictation->mode,
            'status' => $dictation->status,
            'locale' => $dictation->locale,
            'audio_path' => $dictation->audio_path,
            'transcript' => $dictation->transcript,
            'summary' => $dictation->summary,
            'processed_offline' => $dictation->processed_offline,
            'duration_seconds' => $dictation->duration_seconds,
            'meta' => $dictation->meta,
            'created_at' => $dictation->created_at?->toIso8601String(),
            'updated_at' => $dictation->updated_at?->toIso8601String(),
        ];
    }
}
