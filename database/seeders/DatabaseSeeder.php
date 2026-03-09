<?php

namespace Database\Seeders;

use App\Models\Appointment;
use App\Models\Clinic;
use App\Models\ConsentTemplate;
use App\Models\NoteTemplate;
use App\Models\OnboardingForm;
use App\Models\OnboardingResponse;
use App\Models\Patient;
use App\Models\PatientConsent;
use App\Models\Provider;
use App\Models\User;
use App\Models\Visit;
// use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call(Phase4RbacSeeder::class);

        $clinic = Clinic::query()->firstOrCreate([
            'slug' => 'demo-primary-care',
        ], [
            'name' => 'MediNotes Demo Clinic',
            'registration_number' => 'CLINIC-DEMO-001',
            'phone' => '+27 11 555 0100',
            'email' => 'hello@medinotes.local',
            'timezone' => 'Africa/Johannesburg',
            'settings' => [
                'locale' => 'en-ZA',
                'clinical_timezone' => 'Africa/Johannesburg',
            ],
            'is_active' => true,
        ]);

        $doctor = User::factory()->admin()->create([
            'name' => 'Test User',
            'email' => 'test@example.com',
        ]);

        $doctor->syncRoles('admin');

        $provider = Provider::query()->updateOrCreate([
            'user_id' => $doctor->id,
        ], [
            'clinic_id' => $clinic->id,
            'professional_number' => 'HPCSA-DEMO-1001',
            'first_name' => 'Test',
            'last_name' => 'User',
            'specialty' => 'Primary Care',
            'phone' => '+27 82 000 0001',
            'email' => $doctor->email,
            'metadata' => [
                'source' => 'database-seeder',
            ],
            'is_active' => true,
        ]);

        $historyTemplate = NoteTemplate::query()->create([
            'title' => 'General Clinic Follow-up',
            'specialty' => 'Primary Care',
            'template_body' => "Subjective\n- Chief complaint\n- HPI\n\nObjective\n- Vitals\n- Exam\n\nAssessment\n- Differential\n\nPlan\n- Investigations\n- Treatment\n- Follow-up",
            'sections' => ['Subjective', 'Objective', 'Assessment', 'Plan'],
            'is_system' => true,
            'created_by' => $doctor->id,
        ]);

        $patient = Patient::query()->create([
            'clinic_id' => $clinic->id,
            'medical_record_number' => 'MRN-DEMO-0001',
            'title' => 'Ms',
            'first_name' => 'Amelia',
            'last_name' => 'Smith',
            'preferred_name' => 'Amy',
            'date_of_birth' => '1988-05-21',
            'sex' => 'female',
            'phone' => '+44 7700 900111',
            'alternate_phone' => '+44 7700 900112',
            'email' => 'amelia.smith@example.com',
            'external_reference' => 'LEGACY-PAT-0001',
            'address_line_1' => '42 Willow Street',
            'city' => 'Johannesburg',
            'province' => 'Gauteng',
            'postal_code' => '2193',
            'country' => 'ZA',
            'allergies' => ['Penicillin'],
            'allergies_summary' => 'Penicillin allergy reported.',
            'medications' => ['Metformin 500 mg BD'],
            'medication_summary' => 'Metformin 500 mg twice daily.',
            'medical_history' => ['Type 2 diabetes', 'Seasonal allergic rhinitis'],
            'medical_history_summary' => 'Type 2 diabetes and seasonal allergic rhinitis.',
            'notes' => 'Prefers evening appointments when available.',
            'alerts' => ['Check allergy status before prescribing antibiotics.'],
            'has_alerts' => true,
            'last_visit_at' => now()->subWeeks(4),
        ]);

        Visit::query()->create([
            'patient_id' => $patient->id,
            'clinician_id' => $doctor->id,
            'note_template_id' => $historyTemplate->id,
            'encounter_type' => 'follow_up',
            'status' => 'completed',
            'chief_complaint' => 'Medication review and HbA1c follow-up.',
            'conversation_summary' => 'Discussed glucose trends, fatigue, diet adherence, and walking plan.',
            'subjective' => 'Energy improved overall but still struggling with late evening snacking.',
            'objective' => 'No acute distress. Home glucose log reviewed.',
            'assessment' => 'Type 2 diabetes improving with current regimen.',
            'plan' => 'Continue metformin, repeat HbA1c in 3 months, reinforce dietary coaching.',
            'patient_update' => 'Patient understands plan and follow-up timing.',
            'transcript' => 'Doctor reviewed recent glucose logs and patient described fatigue improving since last visit.',
            'privacy_notice_acknowledged_at' => now()->subWeeks(4),
            'recording_consent_obtained_at' => now()->subWeeks(4),
            'recording_consent_method' => 'written',
            'ai_transcription_consent_obtained_at' => now()->subWeeks(4),
            'consent_notes' => 'Patient consented to offline clinical transcription for the consult note.',
            'template_snapshot' => ['title' => 'General Clinic Follow-up'],
            'meta' => ['source' => 'seed-demo'],
            'started_at' => now()->subWeeks(4),
            'completed_at' => now()->subWeeks(4)->addMinutes(18),
            'synced_at' => now()->subWeeks(4)->addMinutes(18),
        ]);

        $onboardingForm = OnboardingForm::query()->updateOrCreate([
            'clinic_id' => $clinic->id,
            'slug' => 'pre-consult-baseline',
            'version' => '1.0',
        ], [
            'created_by' => $doctor->id,
            'title' => 'Pre-consult baseline intake',
            'description' => 'Capture pre-consult symptoms, allergies, medication adherence, and admin readiness.',
            'schema' => [
                'fields' => [
                    [
                        'key' => 'presenting_concern',
                        'label' => 'Presenting concern',
                        'type' => 'textarea',
                        'required' => true,
                    ],
                    [
                        'key' => 'current_medications_confirmed',
                        'label' => 'Current medications confirmed',
                        'type' => 'boolean',
                    ],
                    [
                        'key' => 'allergy_updates',
                        'label' => 'Any new allergies?',
                        'type' => 'select',
                        'options' => ['None', 'Yes - minor', 'Yes - urgent review'],
                        'required' => true,
                    ],
                    [
                        'key' => 'symptom_onset_date',
                        'label' => 'Symptom onset date',
                        'type' => 'date',
                    ],
                ],
            ],
            'is_active' => true,
        ]);

        $consentTemplate = ConsentTemplate::query()->updateOrCreate([
            'clinic_id' => $clinic->id,
            'slug' => 'general-treatment-consent',
            'version' => '2026.03',
        ], [
            'created_by' => $doctor->id,
            'title' => 'General treatment and POPIA consent',
            'consent_type' => 'general',
            'description' => 'General treatment consent with privacy and data-processing acknowledgement.',
            'body' => "I consent to assessment and treatment at MediNotes Demo Clinic. I acknowledge that my information will be handled in line with POPIA and clinic privacy requirements.",
            'is_active' => true,
        ]);

        $appointment = Appointment::query()->updateOrCreate([
            'clinic_id' => $clinic->id,
            'patient_id' => $patient->id,
            'scheduled_for' => now()->addDays(3)->setTime(10, 30),
        ], [
            'provider_id' => $provider->id,
            'booked_by_user_id' => $doctor->id,
            'booking_type' => 'returning_patient',
            'status' => 'confirmed',
            'duration_minutes' => 30,
            'reason_for_visit' => 'Diabetes review and blood pressure follow-up.',
            'notes' => 'Patient requested consolidated review and updated scripts if needed.',
            'booking_channel' => 'admin_capture',
            'confirmed_at' => now(),
        ]);

        OnboardingResponse::query()->updateOrCreate([
            'clinic_id' => $clinic->id,
            'patient_id' => $patient->id,
            'appointment_id' => $appointment->id,
            'onboarding_form_id' => $onboardingForm->id,
        ], [
            'submitted_by_user_id' => $doctor->id,
            'source_channel' => 'admin_capture',
            'responses' => [
                'presenting_concern' => 'Fatigue and blood sugar variability over the past week.',
                'current_medications_confirmed' => true,
                'allergy_updates' => 'None',
                'symptom_onset_date' => now()->subDays(6)->toDateString(),
            ],
            'submitted_at' => now()->subDay(),
        ]);

        PatientConsent::query()->updateOrCreate([
            'clinic_id' => $clinic->id,
            'patient_id' => $patient->id,
            'appointment_id' => $appointment->id,
            'consent_template_id' => $consentTemplate->id,
        ], [
            'captured_by_user_id' => $doctor->id,
            'accepted_by' => 'Amelia Smith',
            'source_channel' => 'in_person',
            'accepted_at' => now()->subDay(),
            'template_version' => $consentTemplate->version,
            'template_snapshot' => [
                'title' => $consentTemplate->title,
                'slug' => $consentTemplate->slug,
                'consent_type' => $consentTemplate->consent_type,
                'version' => $consentTemplate->version,
                'body' => $consentTemplate->body,
            ],
            'accepted_payload' => [
                'captured_in_person' => true,
                'phase' => 'phase_3_demo',
            ],
            'notes' => 'Patient reviewed privacy wording before follow-up appointment.',
        ]);
    }
}
