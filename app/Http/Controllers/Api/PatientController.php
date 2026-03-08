<?php

namespace App\Http\Controllers\Api;

use App\Http\Requests\Patients\ListPatientsRequest;
use App\Http\Requests\Patients\SearchPatientsRequest;
use App\Http\Requests\Patients\StorePatientRequest;
use App\Http\Requests\Patients\UpdatePatientRequest;
use App\Http\Controllers\Controller;
use App\Http\Resources\Patients\PatientResource;
use App\Http\Resources\Patients\PatientSummaryResource;
use App\Http\Resources\Patients\PatientTimelineItemResource;
use App\Models\Patient;
use App\Services\PatientService;
use App\Support\ClinicalAudit;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PatientController extends Controller
{
    public function __construct(
        private readonly PatientService $patients,
    ) {
    }

    public function index(ListPatientsRequest $request): AnonymousResourceCollection
    {
        $this->authorize('viewAny', Patient::class);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $search = trim((string) $request->validated('search', ''));

        if ($search !== '') {
            $patients = $this->patients->search($user, $search, min($request->integer('per_page', 50), 100));

            ClinicalAudit::record(
                request: $request,
                event: 'patient.search',
                context: [
                    'search' => $search,
                    'results_count' => $patients->count(),
                ],
            );

            return PatientResource::collection($patients)->additional([
                'meta' => [
                    'query' => $search,
                    'count' => $patients->count(),
                ],
            ]);
        }

        $patients = $this->patients->list($user, $request->integer('per_page', 25));

        ClinicalAudit::record(
            request: $request,
            event: 'patients.listed',
            context: [
                'per_page' => $request->integer('per_page', 25),
                'results_count' => $patients->count(),
            ],
        );

        return PatientResource::collection($patients);
    }

    public function search(SearchPatientsRequest $request): AnonymousResourceCollection
    {
        $this->authorize('viewAny', Patient::class);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $query = trim((string) $request->validated('query'));
        $patients = $this->patients->search($user, $query, $request->integer('limit', 25));

        ClinicalAudit::record(
            request: $request,
            event: 'patient.search',
            context: [
                'query' => $query,
                'results_count' => $patients->count(),
            ],
        );

        return PatientResource::collection($patients)->additional([
            'meta' => [
                'query' => $query,
                'count' => $patients->count(),
            ],
        ]);
    }

    public function show(Request $request, Patient $patient): PatientResource
    {
        $this->authorize('view', $patient);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $patient = $this->patients->detail($user, $patient);

        ClinicalAudit::record(
            request: $request,
            event: 'patient.viewed',
            auditable: $patient,
            context: [
                'visits_count' => $patient->visits->count(),
            ],
            patientId: $patient->id,
        );

        return new PatientResource($patient);
    }

    public function store(StorePatientRequest $request): JsonResponse
    {
        $this->authorize('create', Patient::class);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $patient = $this->patients->create($user, $request->validated());

        ClinicalAudit::record(
            request: $request,
            event: 'patient.created',
            auditable: $patient,
            patientId: $patient->id,
        );

        return (new PatientResource($patient))
            ->response()
            ->setStatusCode(201);
    }

    public function update(UpdatePatientRequest $request, string $patientId): JsonResponse
    {
        $existing = Patient::query()->find($patientId);
        $this->authorize($existing ? 'update' : 'create', $existing ?? Patient::class);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $payload = [
            ...$request->validated(),
            'id' => $patientId,
        ];

        $patient = $existing
            ? $this->patients->update($user, $existing, $request->validated())
            : $this->patients->create($user, $payload);

        ClinicalAudit::record(
            request: $request,
            event: $existing ? 'patient.updated' : 'patient.created',
            auditable: $patient,
            patientId: $patient->id,
        );

        return (new PatientResource($patient))->response();
    }

    public function summary(Request $request, Patient $patient): PatientSummaryResource
    {
        $this->authorize('view', $patient);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $patient = $this->patients->summary($user, $patient);

        ClinicalAudit::record(
            request: $request,
            event: 'patient.summary.viewed',
            auditable: $patient,
            patientId: $patient->id,
        );

        return new PatientSummaryResource($patient);
    }

    public function timeline(Request $request, Patient $patient): AnonymousResourceCollection
    {
        $this->authorize('view', $patient);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $timeline = $this->patients->timeline($user, $patient);

        ClinicalAudit::record(
            request: $request,
            event: 'patient.timeline.viewed',
            auditable: $patient,
            context: [
                'timeline_entries' => $timeline->count(),
            ],
            patientId: $patient->id,
        );

        return PatientTimelineItemResource::collection($timeline)->additional([
            'meta' => [
                'patient_id' => $patient->id,
                'count' => $timeline->count(),
            ],
        ]);
    }
}
