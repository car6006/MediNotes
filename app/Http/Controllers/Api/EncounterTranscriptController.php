<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Encounters\StoreEncounterTranscriptRequest;
use App\Http\Resources\Transcripts\TranscriptResource;
use App\Models\Encounter;
use App\Models\Transcript;
use App\Services\TranscriptService;
use App\Support\ClinicalAudit;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class EncounterTranscriptController extends Controller
{
    public function __construct(
        private readonly TranscriptService $transcripts,
    ) {
    }

    public function index(Request $request, Encounter $encounter): AnonymousResourceCollection
    {
        $this->authorize('view', $encounter);
        $this->authorize('viewAny', Transcript::class);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $transcripts = $this->transcripts->list($user, $encounter);

        ClinicalAudit::record(
            request: $request,
            event: 'encounter.transcripts.viewed',
            auditable: $encounter,
            context: [
                'count' => $transcripts->count(),
            ],
            patientId: $encounter->patient_id,
        );

        return TranscriptResource::collection($transcripts)->additional([
            'meta' => [
                'encounter_id' => $encounter->id,
                'count' => $transcripts->count(),
            ],
        ]);
    }

    public function store(StoreEncounterTranscriptRequest $request, Encounter $encounter): JsonResponse
    {
        $this->authorize('view', $encounter);
        $this->authorize('create', Transcript::class);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $transcript = $this->transcripts->store($user, $encounter, $request->validated());

        ClinicalAudit::record(
            request: $request,
            event: 'encounter.transcript.created',
            auditable: $encounter,
            context: [
                'transcript_id' => $transcript->id,
                'transcript_type' => $transcript->transcript_type,
            ],
            patientId: $encounter->patient_id,
        );

        return (new TranscriptResource($transcript))
            ->response()
            ->setStatusCode(201);
    }
}
