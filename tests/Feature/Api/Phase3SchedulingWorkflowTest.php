<?php

use App\Models\Clinic;
use App\Models\ConsentTemplate;
use App\Models\OnboardingForm;
use App\Models\Patient;
use App\Models\Provider;
use App\Models\User;
use Laravel\Sanctum\Sanctum;

it('supports phase 3 appointments onboarding and consents end to end', function () {
    $admin = User::factory()->admin()->create();
    $admin->syncRoles('admin');
    Sanctum::actingAs($admin, $admin->tokenAbilities());

    $clinic = Clinic::query()->create([
        'id' => (string) str()->uuid(),
        'name' => 'Phase 3 Test Clinic',
        'slug' => 'phase-3-test-clinic',
        'registration_number' => 'CLINIC-PHASE3-001',
        'is_active' => true,
    ]);

    $provider = Provider::query()->create([
        'id' => (string) str()->uuid(),
        'clinic_id' => $clinic->id,
        'user_id' => $admin->id,
        'professional_number' => 'HPCSA-PHASE3-1001',
        'first_name' => 'Sam',
        'last_name' => 'Nkosi',
        'specialty' => 'Family Medicine',
        'email' => 'sam.nkosi@example.test',
        'is_active' => true,
    ]);

    $patient = Patient::query()->create([
        'id' => (string) str()->uuid(),
        'clinic_id' => $clinic->id,
        'medical_record_number' => 'MRN-PHASE3-0001',
        'first_name' => 'Lebo',
        'last_name' => 'Maseko',
        'phone' => '+27 82 555 0191',
        'email' => 'lebo@example.test',
    ]);

    $onboardingForm = OnboardingForm::query()->create([
        'id' => (string) str()->uuid(),
        'clinic_id' => $clinic->id,
        'created_by' => $admin->id,
        'title' => 'Arrival intake',
        'slug' => 'arrival-intake',
        'version' => '1.0',
        'schema' => [
            'fields' => [
                [
                    'key' => 'presenting_concern',
                    'label' => 'Presenting concern',
                    'type' => 'textarea',
                    'required' => true,
                ],
            ],
        ],
        'is_active' => true,
    ]);

    $consentTemplate = ConsentTemplate::query()->create([
        'id' => (string) str()->uuid(),
        'clinic_id' => $clinic->id,
        'created_by' => $admin->id,
        'title' => 'General consent',
        'slug' => 'general-consent',
        'consent_type' => 'general',
        'body' => 'I consent to treatment and privacy processing at this clinic.',
        'version' => '1.0',
        'is_active' => true,
    ]);

    $newPatientBooking = $this->postJson('/api/v1/appointments', [
        'clinic_id' => $clinic->id,
        'provider_id' => $provider->id,
        'booking_type' => 'new_patient',
        'scheduled_for' => now()->addDays(2)->setTime(9, 0)->toIso8601String(),
        'duration_minutes' => 40,
        'reason_for_visit' => 'New patient booking for cough review',
        'booking_channel' => 'admin_capture',
        'patient' => [
            'first_name' => 'Anele',
            'last_name' => 'Mokoena',
            'phone' => '+27 82 555 0200',
            'email' => 'anele@example.test',
        ],
    ]);

    $newPatientBooking
        ->assertCreated()
        ->assertJsonPath('data.booking_type', 'new_patient')
        ->assertJsonPath('data.patient.full_name', 'Anele Mokoena');

    $returningAppointment = $this->postJson('/api/v1/appointments', [
        'clinic_id' => $clinic->id,
        'patient_id' => $patient->id,
        'provider_id' => $provider->id,
        'booking_type' => 'returning_patient',
        'scheduled_for' => now()->addDay()->setTime(14, 0)->toIso8601String(),
        'duration_minutes' => 30,
        'reason_for_visit' => 'Blood pressure review',
        'notes' => 'Please confirm medication refill status.',
        'booking_channel' => 'admin_capture',
    ]);

    $returningAppointment
        ->assertCreated()
        ->assertJsonPath('data.patient.id', $patient->id)
        ->assertJsonPath('data.status', 'booked');

    $appointmentId = $returningAppointment->json('data.id');

    $this->getJson('/api/v1/appointments')
        ->assertOk()
        ->assertJsonCount(2, 'data');

    $this->getJson("/api/v1/appointments/{$appointmentId}")
        ->assertOk()
        ->assertJsonPath('data.reason_for_visit', 'Blood pressure review');

    $this->patchJson("/api/v1/appointments/{$appointmentId}", [
        'status' => 'arrived',
        'notes' => 'Patient arrived early and is waiting.',
    ])
        ->assertOk()
        ->assertJsonPath('data.status', 'arrived')
        ->assertJsonStructure([
            'data' => [
                'timeline' => ['arrived_at'],
            ],
        ]);

    $this->getJson("/api/v1/patients/{$patient->id}/appointments")
        ->assertOk()
        ->assertJsonPath('meta.patient_id', $patient->id)
        ->assertJsonCount(1, 'data');

    $this->getJson('/api/v1/onboarding/forms')
        ->assertOk()
        ->assertJsonPath('data.0.title', 'Arrival intake');

    $this->postJson('/api/v1/onboarding/responses', [
        'patient_id' => $patient->id,
        'appointment_id' => $appointmentId,
        'onboarding_form_id' => $onboardingForm->id,
        'source_channel' => 'admin_capture',
        'responses' => [
            'presenting_concern' => 'Dizziness and elevated home readings.',
        ],
    ])
        ->assertCreated()
        ->assertJsonPath('data.form.title', 'Arrival intake');

    $this->getJson("/api/v1/patients/{$patient->id}/onboarding")
        ->assertOk()
        ->assertJsonPath('meta.patient_id', $patient->id)
        ->assertJsonCount(1, 'data');

    $this->getJson('/api/v1/consent-templates')
        ->assertOk()
        ->assertJsonPath('data.0.title', 'General consent');

    $this->postJson('/api/v1/consents', [
        'patient_id' => $patient->id,
        'appointment_id' => $appointmentId,
        'consent_template_id' => $consentTemplate->id,
        'accepted_by' => 'Lebo Maseko',
        'source_channel' => 'in_person',
        'accepted_payload' => [
            'witnessed' => true,
        ],
    ])
        ->assertCreated()
        ->assertJsonPath('data.template.title', 'General consent')
        ->assertJsonPath('data.accepted_by', 'Lebo Maseko');

    $this->getJson("/api/v1/patients/{$patient->id}/consents")
        ->assertOk()
        ->assertJsonPath('meta.patient_id', $patient->id)
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.template.version', '1.0');
});
