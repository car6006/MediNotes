<?php

use App\Models\Clinic;
use App\Models\Patient;
use App\Models\User;
use App\Models\Visit;
use Laravel\Sanctum\Sanctum;

it('supports the phase 2 patient registry endpoints end to end', function () {
    $admin = User::factory()->admin()->create();
    Sanctum::actingAs($admin, $admin->tokenAbilities());

    $clinic = Clinic::query()->create([
        'id' => (string) str()->uuid(),
        'name' => 'Phase 2 Test Clinic',
        'slug' => 'phase-2-test-clinic',
        'registration_number' => 'CLINIC-PHASE2-001',
        'is_active' => true,
    ]);

    $createResponse = $this->postJson('/api/v1/patients', [
        'clinic_id' => $clinic->id,
        'medical_record_number' => 'MRN-PHASE2-0001',
        'title' => 'Ms',
        'first_name' => 'Thandi',
        'middle_name' => 'Grace',
        'last_name' => 'Nkosi',
        'preferred_name' => 'TG',
        'date_of_birth' => '1992-10-12',
        'sex' => 'female',
        'phone' => '+27 82 555 0101',
        'alternate_phone' => '+27 82 555 0102',
        'email' => 'thandi@example.test',
        'national_id_number' => '9201015800088',
        'external_reference' => 'EXT-PAT-2026-001',
        'address_line_1' => '12 Protea Road',
        'city' => 'Pretoria',
        'province' => 'Gauteng',
        'postal_code' => '0083',
        'country' => 'ZA',
        'emergency_contact_name' => 'Sipho Nkosi',
        'emergency_contact_phone' => '+27 82 555 0199',
        'medical_history' => ['Hypertension'],
        'allergies' => ['Penicillin'],
        'medications' => ['Amlodipine 5 mg daily'],
        'alerts' => ['Penicillin allergy'],
        'notes' => 'Returning after transfer from another clinic.',
    ]);

    $createResponse
        ->assertCreated()
        ->assertJsonPath('data.full_name', 'Thandi Nkosi')
        ->assertJsonPath('data.clinic.id', $clinic->id)
        ->assertJsonPath('data.identifiers.national_id_number', '9201015800088')
        ->assertJsonPath('data.has_alerts', true);

    $patientId = $createResponse->json('data.id');

    Visit::query()->create([
        'id' => (string) str()->uuid(),
        'patient_id' => $patientId,
        'clinician_id' => $admin->id,
        'encounter_type' => 'follow_up',
        'status' => 'completed',
        'chief_complaint' => 'Medication review',
        'conversation_summary' => 'Patient stable on current treatment plan.',
        'started_at' => now()->subDays(10),
        'completed_at' => now()->subDays(10)->addMinutes(22),
        'synced_at' => now()->subDays(10)->addMinutes(22),
    ]);

    $this->getJson('/api/v1/patients')
        ->assertOk()
        ->assertJsonPath('data.0.full_name', 'Thandi Nkosi');

    $this->getJson('/api/v1/patients/search?query=MRN-PHASE2-0001')
        ->assertOk()
        ->assertJsonPath('meta.query', 'MRN-PHASE2-0001')
        ->assertJsonPath('data.0.full_name', 'Thandi Nkosi');

    $this->getJson("/api/v1/patients/{$patientId}/summary")
        ->assertOk()
        ->assertJsonPath('data.medical_history_summary', 'Hypertension')
        ->assertJsonPath('data.clinic.name', 'Phase 2 Test Clinic');

    $this->getJson("/api/v1/patients/{$patientId}/timeline")
        ->assertOk()
        ->assertJsonPath('meta.patient_id', $patientId)
        ->assertJsonPath('data.0.chief_complaint', 'Medication review');

    $this->putJson("/api/v1/patients/{$patientId}", [
        'preferred_name' => 'Thandi G',
        'medication_summary' => 'Amlodipine 5 mg daily. Monitor BP monthly.',
        'alerts' => ['Penicillin allergy', 'Needs morning appointments'],
    ])
        ->assertOk()
        ->assertJsonPath('data.preferred_name', 'Thandi G')
        ->assertJsonPath('data.medication_summary', 'Amlodipine 5 mg daily. Monitor BP monthly.')
        ->assertJsonPath('data.has_alerts', true);

    expect(Patient::query()->findOrFail($patientId)->clinic_id)->toBe($clinic->id);
});
