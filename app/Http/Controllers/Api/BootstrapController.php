<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\SerializesClinicalPayloads;
use App\Http\Controllers\Controller;
use App\Models\NoteTemplate;
use App\Models\Patient;
use App\Models\Visit;
use App\Support\ClinicalAudit;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BootstrapController extends Controller
{
    use SerializesClinicalPayloads;

    public function __invoke(Request $request): JsonResponse
    {
        $patients = Patient::query()
            ->with('visits')
            ->latest('updated_at')
            ->limit(12)
            ->get();

        $visits = Visit::query()
            ->with(['patient', 'template', 'dictations'])
            ->latest('started_at')
            ->limit(12)
            ->get();

        $templates = NoteTemplate::query()
            ->latest('updated_at')
            ->get();

        ClinicalAudit::record(
            request: $request,
            event: 'bootstrap.viewed',
            context: [
                'patients_count' => $patients->count(),
                'visits_count' => $visits->count(),
                'templates_count' => $templates->count(),
            ],
        );

        return response()->json([
            'data' => [
                'patients' => $patients->map(fn (Patient $patient) => $this->patientData($patient))->values(),
                'visits' => $visits->map(fn (Visit $visit) => $this->visitData($visit))->values(),
                'templates' => $templates->map(fn (NoteTemplate $template) => $this->templateData($template))->values(),
            ],
            'meta' => [
                'generated_at' => now()->toIso8601String(),
                'workflow' => 'doctor-patient-dictation-template-sync',
                'transcription' => [
                    'short_form' => 'speech_to_text_on_device',
                    'long_form' => 'flutter_whisper_offline',
                ],
                'security' => [
                    'privacy_notice_version' => config('clinical.privacy_notice_version'),
                    'audit_logging' => true,
                    'recording_requires_consent' => true,
                    'local_cache_encryption_required' => true,
                ],
            ],
        ]);
    }
}
