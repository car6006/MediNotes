<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Notes\SignClinicalNoteRequest;
use App\Http\Requests\Notes\UpdateClinicalNoteRequest;
use App\Http\Resources\Notes\ClinicalNoteResource;
use App\Http\Resources\Notes\ClinicalNoteVersionResource;
use App\Models\ClinicalNote;
use App\Services\ClinicalNoteService;
use App\Support\ClinicalAudit;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class ClinicalNoteController extends Controller
{
    public function __construct(
        private readonly ClinicalNoteService $notes,
    ) {
    }

    public function show(Request $request, ClinicalNote $clinicalNote): ClinicalNoteResource
    {
        $this->authorize('view', $clinicalNote);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $note = $this->notes->detail($user, $clinicalNote);

        ClinicalAudit::record(
            request: $request,
            event: 'clinical_note.viewed',
            auditable: $note,
        );

        return new ClinicalNoteResource($note);
    }

    public function update(UpdateClinicalNoteRequest $request, ClinicalNote $clinicalNote): JsonResponse
    {
        $this->authorize('update', $clinicalNote);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $note = $this->notes->update($user, $clinicalNote, $request->validated());

        ClinicalAudit::record(
            request: $request,
            event: 'clinical_note.updated',
            auditable: $note,
        );

        return (new ClinicalNoteResource($note))->response();
    }

    public function sign(SignClinicalNoteRequest $request, ClinicalNote $clinicalNote): JsonResponse
    {
        $this->authorize('sign', $clinicalNote);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $note = $this->notes->sign($user, $clinicalNote, $request->validated());

        ClinicalAudit::record(
            request: $request,
            event: 'clinical_note.signed',
            auditable: $note,
        );

        return (new ClinicalNoteResource($note))->response();
    }

    public function versions(Request $request, ClinicalNote $clinicalNote): AnonymousResourceCollection
    {
        $this->authorize('view', $clinicalNote);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $note = $this->notes->detail($user, $clinicalNote);
        $versions = $this->notes->versions($user, $clinicalNote);

        ClinicalAudit::record(
            request: $request,
            event: 'clinical_note.versions.viewed',
            auditable: $note,
        );

        return ClinicalNoteVersionResource::collection($versions)->additional([
            'meta' => [
                'clinical_note_id' => $note->id,
                'encounter_id' => $note->encounter_id,
                'count' => $versions->count(),
            ],
        ]);
    }
}
