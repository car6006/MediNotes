<?php

namespace App\Repositories;

use App\Enums\TranscriptType;
use App\Models\Encounter;
use App\Models\Transcript;
use Illuminate\Database\Eloquent\Collection;

class TranscriptRepository
{
    /**
     * @param  array<string, mixed>  $attributes
     */
    public function create(array $attributes): Transcript
    {
        return Transcript::query()->create($attributes);
    }

    /**
     * @return Collection<int, Transcript>
     */
    public function forEncounter(Encounter $encounter): Collection
    {
        return Transcript::query()
            ->with(['audioFile', 'generatedBy', 'reviewedBy'])
            ->where('encounter_id', $encounter->id)
            ->orderByDesc('created_at')
            ->get();
    }

    public function latestForEncounter(Encounter $encounter, TranscriptType $type): ?Transcript
    {
        return Transcript::query()
            ->where('encounter_id', $encounter->id)
            ->where('transcript_type', $type->value)
            ->latest()
            ->first();
    }
}