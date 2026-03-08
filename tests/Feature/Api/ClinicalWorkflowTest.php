<?php

use App\Models\NoteTemplate;
use App\Models\Patient;
use App\Models\User;
use App\Models\Visit;
use Laravel\Sanctum\Sanctum;

it('creates a patient visit and offline dictation workflow', function () {
    $doctor = User::factory()->create();
    Sanctum::actingAs($doctor, $doctor->tokenAbilities());

    $template = NoteTemplate::query()->create([
        'title' => 'SOAP Visit',
        'specialty' => 'Primary Care',
        'template_body' => 'Subjective\nObjective\nAssessment\nPlan',
        'sections' => ['Subjective', 'Objective', 'Assessment', 'Plan'],
        'is_system' => true,
        'created_by' => $doctor->id,
    ]);

    $patientResponse = $this->postJson('/api/v1/patients', [
        'id' => (string) str()->uuid(),
        'first_name' => 'Nina',
        'last_name' => 'Patel',
        'date_of_birth' => '1990-04-01',
        'sex' => 'female',
        'phone' => '+44 7700 900222',
        'allergies' => ['Latex'],
        'medications' => ['Salbutamol inhaler'],
        'medical_history' => ['Asthma'],
    ]);

    $patientResponse
        ->assertCreated()
        ->assertJsonPath('data.full_name', 'Nina Patel');

    $patientId = $patientResponse->json('data.id');

    $visitResponse = $this->postJson('/api/v1/visits', [
        'id' => (string) str()->uuid(),
        'patient_id' => $patientId,
        'clinician_id' => $doctor->id,
        'note_template_id' => $template->id,
        'encounter_type' => 'new_patient',
        'status' => 'in_progress',
        'chief_complaint' => 'Persistent cough for 10 days',
        'subjective' => 'Dry cough, no chest pain, mild wheeze at night.',
        'plan' => 'Peak flow review and inhaler check.',
        'privacy_notice_acknowledged_at' => now()->toIso8601String(),
        'recording_consent_obtained_at' => now()->toIso8601String(),
        'recording_consent_method' => 'verbal',
        'ai_transcription_consent_obtained_at' => now()->toIso8601String(),
    ]);

    $visitResponse
        ->assertCreated()
        ->assertJsonPath('data.patient_id', $patientId);

    $visitId = $visitResponse->json('data.id');

    $this->postJson("/api/v1/visits/{$visitId}/dictations", [
        'mode' => 'offline_whisper',
        'status' => 'completed',
        'transcript' => 'Patient reports cough began after viral illness and is worse overnight.',
        'summary' => 'Respiratory symptoms captured offline.',
        'processed_offline' => true,
        'append_to_visit' => true,
    ])->assertCreated();

    $this->getJson("/api/v1/visits/{$visitId}")
        ->assertOk()
        ->assertJsonPath('data.template.title', 'SOAP Visit')
        ->assertJsonCount(1, 'data.dictations')
        ->assertJsonPath('data.dictations.0.mode', 'offline_whisper');

    expect($this->getJson("/api/v1/visits/{$visitId}")->json('data.transcript'))
        ->toContain('Patient reports cough began after viral illness');
});

it('finds returning patients and includes visit history', function () {
    $doctor = User::factory()->create();
    Sanctum::actingAs($doctor, $doctor->tokenAbilities());

    $patient = Patient::query()->create([
        'id' => (string) str()->uuid(),
        'medical_record_number' => 'MRN-LOOKUP-0001',
        'first_name' => 'Daniel',
        'last_name' => 'Okafor',
        'medical_history' => ['Hypertension'],
    ]);

    Visit::query()->create([
        'id' => (string) str()->uuid(),
        'patient_id' => $patient->id,
        'encounter_type' => 'follow_up',
        'status' => 'completed',
        'chief_complaint' => 'Blood pressure review',
        'started_at' => now()->subMonth(),
    ]);

    Visit::query()->create([
        'id' => (string) str()->uuid(),
        'patient_id' => $patient->id,
        'encounter_type' => 'follow_up',
        'status' => 'completed',
        'chief_complaint' => 'Medication adjustment',
        'started_at' => now()->subWeek(),
    ]);

    $this->getJson('/api/v1/patients?search=LOOKUP-0001')
        ->assertOk()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.full_name', 'Daniel Okafor');

    $this->getJson("/api/v1/patients/{$patient->id}")
        ->assertOk()
        ->assertJsonPath('data.visits_count', 2)
        ->assertJsonCount(2, 'data.visits');
});

it('requires consent metadata before storing offline dictation', function () {
    $doctor = User::factory()->create();
    Sanctum::actingAs($doctor, $doctor->tokenAbilities());

    $patient = Patient::query()->create([
        'id' => (string) str()->uuid(),
        'medical_record_number' => 'MRN-CONSENT-0001',
        'first_name' => 'Amina',
        'last_name' => 'Dube',
    ]);

    $visit = Visit::query()->create([
        'id' => (string) str()->uuid(),
        'patient_id' => $patient->id,
        'clinician_id' => $doctor->id,
        'encounter_type' => 'follow_up',
        'status' => 'in_progress',
        'started_at' => now(),
    ]);

    $this->postJson("/api/v1/visits/{$visit->id}/dictations", [
        'mode' => 'offline_whisper',
        'status' => 'completed',
        'transcript' => 'Offline dictation should not persist without explicit consent.',
    ])
        ->assertUnprocessable()
        ->assertJsonValidationErrors(['recording_consent_obtained_at']);
});
