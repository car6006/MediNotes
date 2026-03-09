<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\AppointmentController;
use App\Http\Controllers\Api\BootstrapController;
use App\Http\Controllers\Api\ClinicalNoteController;
use App\Http\Controllers\Api\ConsentController;
use App\Http\Controllers\Api\DictationController;
use App\Http\Controllers\Api\EncounterAudioController;
use App\Http\Controllers\Api\EncounterController;
use App\Http\Controllers\Api\EncounterNoteController;
use App\Http\Controllers\Api\EncounterTemplateController;
use App\Http\Controllers\Api\EncounterTranscriptController;
use App\Http\Controllers\Api\NoteTemplateController;
use App\Http\Controllers\Api\OnboardingController;
use App\Http\Controllers\Api\PatientController;
use App\Http\Controllers\Api\VisitController;
use App\Http\Middleware\EnsureApiUserHasClinicalAccess;
use App\Http\Middleware\PreventClinicalApiCaching;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->middleware([PreventClinicalApiCaching::class])->group(function () {
    Route::post('auth/login', [AuthController::class, 'login']);

    Route::middleware(['auth:sanctum', EnsureApiUserHasClinicalAccess::class])->group(function () {
        Route::get('auth/me', [AuthController::class, 'me']);
        Route::post('auth/logout', [AuthController::class, 'logout']);

        Route::get('bootstrap', BootstrapController::class);

        Route::get('patients', [PatientController::class, 'index']);
        Route::get('patients/search', [PatientController::class, 'search']);
        Route::post('patients', [PatientController::class, 'store']);
        Route::get('patients/{patient}/appointments', [AppointmentController::class, 'patientAppointments']);
        Route::get('patients/{patient}/encounters', [EncounterController::class, 'patientEncounters']);
        Route::get('patients/{patient}/onboarding', [OnboardingController::class, 'patientOnboarding']);
        Route::get('patients/{patient}/consents', [ConsentController::class, 'patientConsents']);
        Route::get('patients/{patient}/summary', [PatientController::class, 'summary']);
        Route::get('patients/{patient}/timeline', [PatientController::class, 'timeline']);
        Route::get('patients/{patient}', [PatientController::class, 'show']);
        Route::put('patients/{patientId}', [PatientController::class, 'update']);
        Route::patch('patients/{patientId}', [PatientController::class, 'update']);

        Route::get('appointments', [AppointmentController::class, 'index']);
        Route::post('appointments', [AppointmentController::class, 'store']);
        Route::get('appointments/{appointment}', [AppointmentController::class, 'show']);
        Route::put('appointments/{appointment}', [AppointmentController::class, 'update']);
        Route::patch('appointments/{appointment}', [AppointmentController::class, 'update']);

        Route::get('onboarding/forms', [OnboardingController::class, 'forms']);
        Route::post('onboarding/responses', [OnboardingController::class, 'storeResponse']);

        Route::get('consent-templates', [ConsentController::class, 'templates']);
        Route::post('consents', [ConsentController::class, 'store']);

        Route::get('visits', [VisitController::class, 'index']);
        Route::post('visits', [VisitController::class, 'store']);
        Route::get('visits/{visit}', [VisitController::class, 'show']);
        Route::put('visits/{visitId}', [VisitController::class, 'upsert']);
        Route::patch('visits/{visitId}', [VisitController::class, 'upsert']);

        Route::get('encounters', [EncounterController::class, 'index']);
        Route::post('encounters', [EncounterController::class, 'store']);
        Route::get('encounters/{encounter}', [EncounterController::class, 'show']);
        Route::put('encounters/{encounter}', [EncounterController::class, 'update']);
        Route::patch('encounters/{encounter}', [EncounterController::class, 'update']);
        Route::post('encounters/{encounter}/audio', [EncounterAudioController::class, 'store']);
        Route::get('encounters/{encounter}/transcripts', [EncounterTranscriptController::class, 'index']);
        Route::post('encounters/{encounter}/transcripts', [EncounterTranscriptController::class, 'store']);
        Route::post('encounters/{encounter}/notes', [EncounterNoteController::class, 'store']);

        Route::get('notes/{clinicalNote}', [ClinicalNoteController::class, 'show']);
        Route::put('notes/{clinicalNote}', [ClinicalNoteController::class, 'update']);
        Route::patch('notes/{clinicalNote}', [ClinicalNoteController::class, 'update']);
        Route::post('notes/{clinicalNote}/sign', [ClinicalNoteController::class, 'sign']);
        Route::get('notes/{clinicalNote}/versions', [ClinicalNoteController::class, 'versions']);

        Route::get('note-templates', [NoteTemplateController::class, 'index']);
        Route::post('note-templates', [NoteTemplateController::class, 'store']);
        Route::put('note-templates/{templateId}', [NoteTemplateController::class, 'upsert']);
        Route::patch('note-templates/{templateId}', [NoteTemplateController::class, 'upsert']);

        Route::get('encounter-templates', [EncounterTemplateController::class, 'index']);
        Route::post('encounter-templates', [EncounterTemplateController::class, 'store']);
        Route::get('encounter-templates/{encounterTemplate}', [EncounterTemplateController::class, 'show']);
        Route::put('encounter-templates/{encounterTemplate}', [EncounterTemplateController::class, 'update']);
        Route::patch('encounter-templates/{encounterTemplate}', [EncounterTemplateController::class, 'update']);

        Route::post('visits/{visit}/dictations', [DictationController::class, 'store']);
    });
});
