<?php

use App\Models\Appointment;
use App\Models\Clinic;
use App\Models\Patient;
use App\Models\Provider;
use App\Models\User;
use Database\Seeders\Phase4RbacSeeder;
use Laravel\Sanctum\Sanctum;

beforeEach(function () {
    $this->seed(Phase4RbacSeeder::class);

    $this->user = User::factory()->admin()->create();
    $this->user->syncRoles('admin');
    Sanctum::actingAs($this->user, $this->user->tokenAbilities());

    $this->clinic = Clinic::query()->create([
        'id' => (string) str()->uuid(),
        'name' => 'Phase 4 Workflow Clinic',
        'slug' => 'phase-4-workflow-clinic',
        'registration_number' => 'CLINIC-PHASE4-001',
        'is_active' => true,
    ]);

    $this->provider = Provider::query()->create([
        'id' => (string) str()->uuid(),
        'clinic_id' => $this->clinic->id,
        'user_id' => $this->user->id,
        'professional_number' => 'HPCSA-PHASE4-1001',
        'first_name' => 'Rina',
        'last_name' => 'Naidoo',
        'specialty' => 'Family Medicine',
        'email' => 'rina.naidoo@example.test',
        'is_active' => true,
    ]);

    $this->patient = Patient::query()->create([
        'id' => (string) str()->uuid(),
        'clinic_id' => $this->clinic->id,
        'medical_record_number' => 'MRN-PHASE4-0001',
        'first_name' => 'Thabo',
        'last_name' => 'Dlamini',
        'phone' => '+27 82 555 0301',
        'email' => 'thabo@example.test',
    ]);

    $this->appointment = Appointment::query()->create([
        'id' => (string) str()->uuid(),
        'clinic_id' => $this->clinic->id,
        'patient_id' => $this->patient->id,
        'provider_id' => $this->provider->id,
        'booked_by_user_id' => $this->user->id,
        'booking_type' => 'returning_patient',
        'status' => 'confirmed',
        'scheduled_for' => now()->addDay()->setTime(10, 0),
        'duration_minutes' => 30,
        'reason_for_visit' => 'Fatigue and blood pressure review',
        'booking_channel' => 'admin_capture',
        'confirmed_at' => now(),
    ]);
});

it('supports the phase 4 encounter workflow end to end', function () {
    $templateResponse = $this->postJson('/api/v1/encounter-templates', [
        'clinic_id' => $this->clinic->id,
        'title' => 'Primary Care SOAP',
        'specialty' => 'Family Medicine',
        'template_body' => "Subjective\nObjective\nAssessment\nPlan",
        'instructions' => 'Capture a concise SOAP note.',
        'encounter_sections' => [
            ['key' => 'subjective', 'label' => 'Subjective', 'position' => 1, 'is_required' => true],
            ['key' => 'objective', 'label' => 'Objective', 'position' => 2, 'is_required' => true],
            ['key' => 'assessment', 'label' => 'Assessment', 'position' => 3, 'is_required' => true],
            ['key' => 'plan', 'label' => 'Plan', 'position' => 4, 'is_required' => true],
        ],
    ]);

    $templateResponse
        ->assertCreated()
        ->assertJsonPath('data.title', 'Primary Care SOAP')
        ->assertJsonPath('data.encounter_sections.0.key', 'subjective');

    $templateId = $templateResponse->json('data.id');

    $encounterResponse = $this->postJson('/api/v1/encounters', [
        'clinic_id' => $this->clinic->id,
        'patient_id' => $this->patient->id,
        'appointment_id' => $this->appointment->id,
        'provider_id' => $this->provider->id,
        'encounter_template_id' => $templateId,
        'chief_complaint' => 'Fatigue, headaches, and elevated blood pressure readings.',
        'privacy_notice_acknowledged_at' => now()->toIso8601String(),
        'recording_consent_obtained_at' => now()->toIso8601String(),
        'recording_consent_method' => 'written',
        'ai_transcription_consent_obtained_at' => now()->toIso8601String(),
        'consent_notes' => 'Patient consented to offline dictation and transcript storage.',
        'started_at' => now()->toIso8601String(),
    ]);

    $encounterResponse
        ->assertCreated()
        ->assertJsonPath('data.status', 'created')
        ->assertJsonPath('data.patient_id', $this->patient->id)
        ->assertJsonPath('data.encounter_template.id', $templateId);

    $encounterId = $encounterResponse->json('data.id');

    $this->patchJson("/api/v1/encounters/{$encounterId}", [
        'status' => 'in_progress',
    ])
        ->assertOk()
        ->assertJsonPath('data.status', 'in_progress')
        ->assertJsonPath('data.timeline.in_progress_at', fn ($value) => filled($value));

    $this->postJson("/api/v1/encounters/{$encounterId}/audio", [
        'storage_path' => 'encounters/audio/test-audio-1.m4a',
        'original_filename' => 'test-audio-1.m4a',
        'mime_type' => 'audio/mp4',
        'duration_seconds' => 93,
        'capture_mode' => 'offline_whisper',
        'captured_at' => now()->toIso8601String(),
    ])
        ->assertCreated()
        ->assertJsonPath('data.capture_mode', 'offline_whisper');

    $this->postJson("/api/v1/encounters/{$encounterId}/transcripts", [
        'transcript_type' => 'raw',
        'source_engine' => 'offline_whisper',
        'content' => 'Patient describes fatigue over the last two weeks with intermittent headaches and poor sleep.',
        'language' => 'en',
        'confidence' => 91.5,
    ])
        ->assertCreated()
        ->assertJsonPath('data.transcript_type', 'raw');

    $this->postJson("/api/v1/encounters/{$encounterId}/transcripts", [
        'transcript_type' => 'cleaned',
        'source_engine' => 'manual_review',
        'content' => 'Fatigue for two weeks with intermittent headaches. No chest pain or dyspnoea. Sleep has been poor.',
        'language' => 'en',
        'confidence' => 98.2,
    ])
        ->assertCreated()
        ->assertJsonPath('data.transcript_type', 'cleaned');

    $noteResponse = $this->postJson("/api/v1/encounters/{$encounterId}/notes", [
        'status' => 'doctor_review_pending',
        'generate_with_medicai' => false,
        'change_summary' => 'Initial clinician draft created.',
    ]);

    $noteResponse
        ->assertCreated()
        ->assertJsonPath('data.status', 'doctor_review_pending')
        ->assertJsonPath('data.current_version_number', 1);

    $noteId = $noteResponse->json('data.id');

    $this->postJson("/api/v1/notes/{$noteId}/sign", [
        'signature_statement' => 'Reviewed and signed by attending clinician.',
    ])
        ->assertOk()
        ->assertJsonPath('data.status', 'signed_off')
        ->assertJsonPath('data.current_version.is_locked', true);

    $this->patchJson("/api/v1/encounters/{$encounterId}", [
        'status' => 'completed',
    ])
        ->assertOk()
        ->assertJsonPath('data.status', 'completed');

    $this->getJson("/api/v1/encounters/{$encounterId}")
        ->assertOk()
        ->assertJsonPath('data.status', 'completed')
        ->assertJsonPath('data.counts.audio_files', 1)
        ->assertJsonPath('data.counts.transcripts', 2)
        ->assertJsonPath('data.current_clinical_note.status', 'signed_off');

    $this->getJson("/api/v1/patients/{$this->patient->id}/encounters")
        ->assertOk()
        ->assertJsonPath('meta.patient_id', $this->patient->id)
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.id', $encounterId);
});
