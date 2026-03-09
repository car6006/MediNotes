<?php

namespace App\Repositories;

use App\Models\AudioFile;
use App\Models\Encounter;
use Illuminate\Database\Eloquent\Collection;

class AudioFileRepository
{
    /**
     * @param  array<string, mixed>  $attributes
     */
    public function create(array $attributes): AudioFile
    {
        return AudioFile::query()->create($attributes);
    }

    /**
     * @return Collection<int, AudioFile>
     */
    public function forEncounter(Encounter $encounter): Collection
    {
        return AudioFile::query()
            ->with('uploadedBy')
            ->where('encounter_id', $encounter->id)
            ->orderByDesc('captured_at')
            ->orderByDesc('created_at')
            ->get();
    }
}