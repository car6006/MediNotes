<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Encounters\StoreEncounterAudioRequest;
use App\Http\Resources\Audio\AudioFileResource;
use App\Models\AudioFile;
use App\Models\Encounter;
use App\Services\EncounterService;
use App\Support\ClinicalAudit;
use Illuminate\Http\JsonResponse;

class EncounterAudioController extends Controller
{
    public function __construct(
        private readonly EncounterService $encounters,
    ) {
    }

    public function store(StoreEncounterAudioRequest $request, Encounter $encounter): JsonResponse
    {
        $this->authorize('update', $encounter);
        $this->authorize('create', AudioFile::class);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $audioFile = $this->encounters->registerAudio($user, $encounter, $request->validated());

        ClinicalAudit::record(
            request: $request,
            event: 'encounter.audio.registered',
            auditable: $encounter,
            context: [
                'audio_file_id' => $audioFile->id,
                'capture_mode' => $audioFile->capture_mode,
            ],
            patientId: $encounter->patient_id,
        );

        return (new AudioFileResource($audioFile))
            ->response()
            ->setStatusCode(201);
    }
}
