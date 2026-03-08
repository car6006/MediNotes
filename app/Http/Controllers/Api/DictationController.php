<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\SerializesClinicalPayloads;
use App\Http\Controllers\Controller;
use App\Models\Dictation;
use App\Models\Visit;
use App\Support\ClinicalAudit;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class DictationController extends Controller
{
    use SerializesClinicalPayloads;

    public function store(Request $request, Visit $visit): JsonResponse
    {
        $this->authorize('recordDictation', $visit);

        $data = $request->validate([
            'id' => ['sometimes', 'uuid'],
            'mode' => ['nullable', 'string', 'max:255'],
            'status' => ['nullable', 'string', 'max:255'],
            'locale' => ['nullable', 'string', 'max:16'],
            'audio_path' => ['nullable', 'string', 'max:2048'],
            'transcript' => ['nullable', 'string'],
            'summary' => ['nullable', 'string'],
            'processed_offline' => ['nullable', 'boolean'],
            'duration_seconds' => ['nullable', 'integer', 'min:0'],
            'meta' => ['nullable', 'array'],
            'append_to_visit' => ['nullable', 'boolean'],
        ]);

        if (config('clinical.dictation.require_recording_consent', true) && ! $visit->recording_consent_obtained_at) {
            throw ValidationException::withMessages([
                'recording_consent_obtained_at' => ['Recording consent must be recorded on the visit before storing dictation.'],
            ]);
        }

        if (config('clinical.dictation.require_ai_consent', true) && filled($data['transcript'] ?? null) && ! $visit->ai_transcription_consent_obtained_at) {
            throw ValidationException::withMessages([
                'ai_transcription_consent_obtained_at' => ['AI transcription consent must be recorded on the visit before storing a transcript.'],
            ]);
        }

        $dictation = Dictation::query()->create([
            'id' => $data['id'] ?? (string) str()->uuid(),
            'visit_id' => $visit->id,
            'mode' => $data['mode'] ?? 'offline_whisper',
            'status' => $data['status'] ?? 'completed',
            'locale' => $data['locale'] ?? null,
            'audio_path' => $data['audio_path'] ?? null,
            'transcript' => $data['transcript'] ?? null,
            'summary' => $data['summary'] ?? null,
            'processed_offline' => (bool) ($data['processed_offline'] ?? true),
            'duration_seconds' => $data['duration_seconds'] ?? null,
            'meta' => $data['meta'] ?? null,
        ]);

        if (($data['append_to_visit'] ?? true) && filled($dictation->transcript)) {
            $visit->update([
                'transcript' => trim(implode("\n\n", array_filter([
                    $visit->transcript,
                    $dictation->transcript,
                ]))),
                'synced_at' => now(),
            ]);
        }

        ClinicalAudit::record(
            request: $request,
            event: 'dictation.created',
            auditable: $visit,
            context: [
                'mode' => $dictation->mode,
                'processed_offline' => $dictation->processed_offline,
                'appended_to_visit' => (bool) ($data['append_to_visit'] ?? true),
            ],
            patientId: $visit->patient_id,
        );

        return response()->json([
            'data' => $this->dictationData($dictation),
        ], 201);
    }
}
