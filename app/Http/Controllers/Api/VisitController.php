<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\SerializesClinicalPayloads;
use App\Http\Controllers\Controller;
use App\Models\Visit;
use App\Support\ClinicalAudit;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Validator as ValidatorContract;

class VisitController extends Controller
{
    use SerializesClinicalPayloads;

    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Visit::class);

        $patientId = $request->string('patient_id')->toString();

        $visits = Visit::query()
            ->with(['patient', 'template', 'dictations'])
            ->when($patientId !== '', fn ($query) => $query->where('patient_id', $patientId))
            ->latest('started_at')
            ->limit($patientId === '' ? 25 : 100)
            ->get();

        ClinicalAudit::record(
            request: $request,
            event: 'visit.list.viewed',
            context: [
                'patient_id' => $patientId !== '' ? $patientId : null,
                'results_count' => $visits->count(),
            ],
            patientId: $patientId !== '' ? $patientId : null,
        );

        return response()->json([
            'data' => $visits->map(fn (Visit $visit) => $this->visitData($visit))->values(),
        ]);
    }

    public function show(Request $request, Visit $visit): JsonResponse
    {
        $this->authorize('view', $visit);

        $visit->load(['patient', 'template', 'dictations']);

        ClinicalAudit::record(
            request: $request,
            event: 'visit.viewed',
            auditable: $visit,
            patientId: $visit->patient_id,
        );

        return response()->json([
            'data' => $this->visitData($visit),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $this->authorize('create', Visit::class);

        $data = $this->validated($request);

        $visit = Visit::query()->create([
            'id' => $data['id'] ?? (string) str()->uuid(),
            ...$this->payload($request, $data),
        ]);

        $visit->patient()->update(['last_visit_at' => $data['started_at'] ?? now()]);

        ClinicalAudit::record(
            request: $request,
            event: 'visit.created',
            auditable: $visit,
            context: [
                'status' => $visit->status,
                'encounter_type' => $visit->encounter_type,
            ],
            patientId: $visit->patient_id,
        );

        return response()->json([
            'data' => $this->visitData($visit->fresh()->load(['patient', 'template', 'dictations'])),
        ], 201);
    }

    public function upsert(Request $request, string $visitId): JsonResponse
    {
        $data = $this->validated($request);
        $existing = Visit::query()->find($visitId);

        $this->authorize($existing ? 'update' : 'create', $existing ?? Visit::class);

        $visit = Visit::query()->updateOrCreate(
            ['id' => $visitId],
            $this->payload($request, $data),
        );

        $visit->patient()->update(['last_visit_at' => $data['started_at'] ?? now()]);

        ClinicalAudit::record(
            request: $request,
            event: $existing ? 'visit.updated' : 'visit.created',
            auditable: $visit,
            context: [
                'status' => $visit->status,
                'encounter_type' => $visit->encounter_type,
            ],
            patientId: $visit->patient_id,
        );

        return response()->json([
            'data' => $this->visitData($visit->fresh()->load(['patient', 'template', 'dictations'])),
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function validated(Request $request): array
    {
        $validator = Validator::make($request->all(), [
            'id' => ['sometimes', 'uuid'],
            'patient_id' => ['required', 'uuid', 'exists:patients,id'],
            'clinician_id' => ['nullable', 'integer', 'exists:users,id'],
            'note_template_id' => ['nullable', 'uuid', 'exists:note_templates,id'],
            'encounter_type' => ['nullable', 'string', 'max:255'],
            'status' => ['nullable', 'string', 'max:255'],
            'chief_complaint' => ['nullable', 'string'],
            'conversation_summary' => ['nullable', 'string'],
            'subjective' => ['nullable', 'string'],
            'objective' => ['nullable', 'string'],
            'assessment' => ['nullable', 'string'],
            'plan' => ['nullable', 'string'],
            'patient_update' => ['nullable', 'string'],
            'transcript' => ['nullable', 'string'],
            'privacy_notice_acknowledged_at' => ['nullable', 'date'],
            'recording_consent_obtained_at' => ['nullable', 'date'],
            'recording_consent_method' => ['nullable', 'string', 'max:255'],
            'ai_transcription_consent_obtained_at' => ['nullable', 'date'],
            'consent_notes' => ['nullable', 'string'],
            'template_snapshot' => ['nullable', 'array'],
            'meta' => ['nullable', 'array'],
            'started_at' => ['nullable', 'date'],
            'completed_at' => ['nullable', 'date'],
            'synced_at' => ['nullable', 'date'],
        ]);

        $validator->after(function (ValidatorContract $validator): void {
            /** @var array<string, mixed> $data */
            $data = $validator->getData();

            if ($this->requiresRecordingConsent($data) && blank($data['privacy_notice_acknowledged_at'] ?? null)) {
                $validator->errors()->add('privacy_notice_acknowledged_at', 'Privacy notice acknowledgement is required before recording or storing clinical dictation.');
            }

            if ($this->requiresRecordingConsent($data) && blank($data['recording_consent_obtained_at'] ?? null)) {
                $validator->errors()->add('recording_consent_obtained_at', 'Recording consent is required before recording or storing clinical dictation.');
            }

            if ($this->requiresRecordingConsent($data) && blank($data['recording_consent_method'] ?? null)) {
                $validator->errors()->add('recording_consent_method', 'Recording consent method is required when dictation is captured.');
            }

            if ($this->requiresAiConsent($data) && blank($data['ai_transcription_consent_obtained_at'] ?? null)) {
                $validator->errors()->add('ai_transcription_consent_obtained_at', 'AI transcription consent is required before storing a transcript.');
            }
        });

        return $validator->validate();
    }

    /**
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    private function payload(Request $request, array $data): array
    {
        return [
            'patient_id' => $data['patient_id'],
            'clinician_id' => $this->resolveClinicianId($request, $data),
            'note_template_id' => $data['note_template_id'] ?? null,
            'encounter_type' => $data['encounter_type'] ?? 'follow_up',
            'status' => $data['status'] ?? 'draft',
            'chief_complaint' => $data['chief_complaint'] ?? null,
            'conversation_summary' => $data['conversation_summary'] ?? null,
            'subjective' => $data['subjective'] ?? null,
            'objective' => $data['objective'] ?? null,
            'assessment' => $data['assessment'] ?? null,
            'plan' => $data['plan'] ?? null,
            'patient_update' => $data['patient_update'] ?? null,
            'transcript' => $data['transcript'] ?? null,
            'privacy_notice_acknowledged_at' => $data['privacy_notice_acknowledged_at'] ?? null,
            'recording_consent_obtained_at' => $data['recording_consent_obtained_at'] ?? null,
            'recording_consent_method' => $data['recording_consent_method'] ?? null,
            'ai_transcription_consent_obtained_at' => $data['ai_transcription_consent_obtained_at'] ?? null,
            'consent_notes' => $data['consent_notes'] ?? null,
            'template_snapshot' => $data['template_snapshot'] ?? null,
            'meta' => $data['meta'] ?? null,
            'started_at' => $data['started_at'] ?? now(),
            'completed_at' => $data['completed_at'] ?? null,
            'synced_at' => $data['synced_at'] ?? null,
        ];
    }

    /**
     * @param  array<string, mixed>  $data
     */
    private function resolveClinicianId(Request $request, array $data): ?int
    {
        $user = $request->user();

        if (! $user) {
            return $data['clinician_id'] ?? null;
        }

        return $user->hasRole('admin')
            ? ($data['clinician_id'] ?? $user->id)
            : $user->id;
    }

    /**
     * @param  array<string, mixed>  $data
     */
    private function requiresRecordingConsent(array $data): bool
    {
        $meta = is_array($data['meta'] ?? null) ? $data['meta'] : [];

        if (! config('clinical.dictation.require_recording_consent', true)) {
            return false;
        }

        return filled($data['transcript'] ?? null)
            || filled($meta['recording_mode'] ?? null)
            || filled($meta['audio_path'] ?? null)
            || (bool) ($meta['dictation_requested'] ?? false);
    }

    /**
     * @param  array<string, mixed>  $data
     */
    private function requiresAiConsent(array $data): bool
    {
        $meta = is_array($data['meta'] ?? null) ? $data['meta'] : [];

        if (! config('clinical.dictation.require_ai_consent', true)) {
            return false;
        }

        return filled($data['transcript'] ?? null)
            || filled($meta['transcription_mode'] ?? null)
            || filled($meta['whisper_model'] ?? null)
            || (bool) ($meta['processed_offline'] ?? false);
    }
}
