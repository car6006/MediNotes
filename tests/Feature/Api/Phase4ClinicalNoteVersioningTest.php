<?php

use App\Models\Clinic;
use App\Models\EncounterTemplate;
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
        'name' => 'Phase 4 Versioning Clinic',
        'slug' => 'phase-4-versioning-clinic',
        'registration_number' => 'CLINIC-PHASE4-002',
        'is_active' => true,
    ]);

    $this->provider = Provider::query()->create([
        'id' => (string) str()->uuid(),
        'clinic_id' => $this->clinic->id,
        'user_id' => $this->user->id,
        'professional_number' => 'HPCSA-PHASE4-1002',
        'first_name' => 'Mpho',
        'last_name' => 'Meyer',
        'specialty' => 'Internal Medicine',
        'email' => 'mpho.meyer@example.test',
        'is_active' => true,
    ]);

    $this->patient = Patient::query()->create([
        'id' => (string) str()->uuid(),
        'clinic_id' => $this->clinic->id,
        'medical_record_number' => 'MRN-PHASE4-0002',
        'first_name' => 'Naledi',
        'last_name' => 'Khoza',
        'phone' => '+27 82 555 0302',
        'email' => 'naledi@example.test',
    ]);

    $this->template = EncounterTemplate::query()->create([
        'id' => (string) str()->uuid(),
        'clinic_id' => $this->clinic->id,
        'title' => 'Internal Medicine SOAP',
        'slug' => 'internal-medicine-soap',
        'version' => '1.0',
        'specialty' => 'Internal Medicine',
        'note_format' => 'soap',
        'template_body' => "Subjective\nObjective\nAssessment\nPlan",
        'sections' => ['Subjective', 'Objective', 'Assessment', 'Plan'],
        'instructions' => 'Use concise, clinically safe wording.',
        'is_system' => false,
        'is_active' => true,
        'created_by' => $this->user->id,
    ]);

    $this->template->encounterSections()->createMany([
        ['id' => (string) str()->uuid(), 'key' => 'subjective', 'label' => 'Subjective', 'position' => 1, 'is_required' => true],
        ['id' => (string) str()->uuid(), 'key' => 'objective', 'label' => 'Objective', 'position' => 2, 'is_required' => true],
        ['id' => (string) str()->uuid(), 'key' => 'assessment', 'label' => 'Assessment', 'position' => 3, 'is_required' => true],
        ['id' => (string) str()->uuid(), 'key' => 'plan', 'label' => 'Plan', 'position' => 4, 'is_required' => true],
    ]);
});

it('creates immutable clinical note versions and reopens review after post-sign edits', function () {
    $encounterResponse = $this->postJson('/api/v1/encounters', [
        'clinic_id' => $this->clinic->id,
        'patient_id' => $this->patient->id,
        'provider_id' => $this->provider->id,
        'encounter_template_id' => $this->template->id,
        'chief_complaint' => 'Persistent dizziness and elevated glucose readings.',
        'privacy_notice_acknowledged_at' => now()->toIso8601String(),
        'recording_consent_obtained_at' => now()->toIso8601String(),
        'recording_consent_method' => 'verbal',
        'ai_transcription_consent_obtained_at' => now()->toIso8601String(),
    ]);

    $encounterId = $encounterResponse->json('data.id');

    $this->patchJson("/api/v1/encounters/{$encounterId}", [
        'status' => 'in_progress',
    ])->assertOk();

    $this->postJson("/api/v1/encounters/{$encounterId}/audio", [
        'storage_path' => 'encounters/audio/versioning-audio.m4a',
        'capture_mode' => 'offline_whisper',
    ])->assertCreated();

    $this->postJson("/api/v1/encounters/{$encounterId}/transcripts", [
        'transcript_type' => 'raw',
        'content' => 'Patient reports dizziness, thirst, and home glucose values trending higher than usual.',
    ])->assertCreated();

    $this->postJson("/api/v1/encounters/{$encounterId}/transcripts", [
        'transcript_type' => 'cleaned',
        'content' => 'Dizziness with thirst and higher home glucose values. No syncope or chest pain.',
    ])->assertCreated();

    $noteResponse = $this->postJson("/api/v1/encounters/{$encounterId}/notes", [
        'status' => 'doctor_review_pending',
        'generate_with_medicai' => false,
    ])->assertCreated();

    $noteId = $noteResponse->json('data.id');

    $this->postJson("/api/v1/notes/{$noteId}/sign", [
        'signature_statement' => 'Signed after clinical review.',
    ])
        ->assertOk()
        ->assertJsonPath('data.current_version.is_locked', true);

    $this->patchJson("/api/v1/notes/{$noteId}", [
        'status' => 'doctor_review_pending',
        'change_summary' => 'Post-sign clarification requested.',
    ])
        ->assertOk()
        ->assertJsonPath('data.status', 'doctor_review_pending')
        ->assertJsonPath('data.current_version_number', 2)
        ->assertJsonPath('data.current_version.source', 'post_sign_revision')
        ->assertJsonPath('data.current_version.is_locked', false);

    $this->getJson("/api/v1/notes/{$noteId}/versions")
        ->assertOk()
        ->assertJsonPath('meta.count', 2)
        ->assertJsonPath('data.0.version_number', 2)
        ->assertJsonPath('data.0.source', 'post_sign_revision')
        ->assertJsonPath('data.1.version_number', 1)
        ->assertJsonPath('data.1.is_locked', true)
        ->assertJsonPath('data.1.change_summary', 'Signed after clinical review.');

    $this->getJson("/api/v1/encounters/{$encounterId}")
        ->assertOk()
        ->assertJsonPath('data.status', 'doctor_review_pending')
        ->assertJsonPath('data.current_clinical_note.current_version_number', 2);
});
