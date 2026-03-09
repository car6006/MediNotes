<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Encounters\StoreEncounterNoteRequest;
use App\Http\Resources\Notes\ClinicalNoteResource;
use App\Models\ClinicalNote;
use App\Models\Encounter;
use App\Services\ClinicalNoteService;
use App\Support\ClinicalAudit;
use Illuminate\Http\JsonResponse;

class EncounterNoteController extends Controller
{
    public function __construct(
        private readonly ClinicalNoteService $notes,
    ) {
    }

    public function store(StoreEncounterNoteRequest $request, Encounter $encounter): JsonResponse
    {
        $this->authorize('update', $encounter);
        $this->authorize('create', ClinicalNote::class);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $note = $this->notes->createDraft($user, $encounter, $request->validated());

        ClinicalAudit::record(
            request: $request,
            event: 'encounter.note.created',
            auditable: $note,
            patientId: $encounter->patient_id,
        );

        return (new ClinicalNoteResource($note))
            ->response()
            ->setStatusCode(201);
    }
}
