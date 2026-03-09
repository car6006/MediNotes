<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Encounters\ListEncountersRequest;
use App\Http\Requests\Encounters\StoreEncounterRequest;
use App\Http\Requests\Encounters\UpdateEncounterRequest;
use App\Http\Resources\Encounters\EncounterResource;
use App\Http\Resources\Encounters\EncounterSummaryResource;
use App\Models\Encounter;
use App\Models\Patient;
use App\Services\EncounterService;
use App\Support\ClinicalAudit;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class EncounterController extends Controller
{
    public function __construct(
        private readonly EncounterService $encounters,
    ) {
    }

    public function index(ListEncountersRequest $request): AnonymousResourceCollection
    {
        $this->authorize('viewAny', Encounter::class);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $encounters = $this->encounters->list(
            $user,
            $request->validated(),
            $request->integer('per_page', 25),
        );

        ClinicalAudit::record(
            request: $request,
            event: 'encounter.listed',
            context: [
                'filters' => $request->validated(),
                'results_count' => $encounters->count(),
            ],
        );

        return EncounterSummaryResource::collection($encounters);
    }

    public function store(StoreEncounterRequest $request): JsonResponse
    {
        $this->authorize('create', Encounter::class);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $encounter = $this->encounters->create($user, $request->validated());

        ClinicalAudit::record(
            request: $request,
            event: 'encounter.created',
            auditable: $encounter,
            patientId: $encounter->patient_id,
        );

        return (new EncounterResource($encounter))
            ->response()
            ->setStatusCode(201);
    }

    public function show(Request $request, Encounter $encounter): EncounterResource
    {
        $this->authorize('view', $encounter);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $encounter = $this->encounters->detail($user, $encounter);

        ClinicalAudit::record(
            request: $request,
            event: 'encounter.viewed',
            auditable: $encounter,
            patientId: $encounter->patient_id,
        );

        return new EncounterResource($encounter);
    }

    public function update(UpdateEncounterRequest $request, Encounter $encounter): JsonResponse
    {
        $this->authorize('update', $encounter);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $encounter = $this->encounters->update($user, $encounter, $request->validated());

        ClinicalAudit::record(
            request: $request,
            event: 'encounter.updated',
            auditable: $encounter,
            patientId: $encounter->patient_id,
        );

        return (new EncounterResource($encounter))->response();
    }

    public function patientEncounters(Request $request, Patient $patient): AnonymousResourceCollection
    {
        $this->authorize('view', $patient);
        $this->authorize('viewAny', Encounter::class);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $encounters = $this->encounters->list(
            $user,
            ['patient_id' => $patient->id],
            $request->integer('per_page', 50),
        );

        ClinicalAudit::record(
            request: $request,
            event: 'patient.encounters.viewed',
            auditable: $patient,
            context: [
                'count' => $encounters->count(),
            ],
            patientId: $patient->id,
        );

        return EncounterSummaryResource::collection($encounters)->additional([
            'meta' => [
                'patient_id' => $patient->id,
                'count' => $encounters->count(),
            ],
        ]);
    }
}
