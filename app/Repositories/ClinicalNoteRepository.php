<?php

namespace App\Repositories;

use App\Models\ClinicalNote;
use App\Models\ClinicalNoteVersion;
use Illuminate\Database\Eloquent\Collection;

class ClinicalNoteRepository
{
    /**
     * @param  array<string, mixed>  $attributes
     */
    public function create(array $attributes): ClinicalNote
    {
        return ClinicalNote::query()->create($attributes);
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function update(ClinicalNote $note, array $attributes): ClinicalNote
    {
        $note->fill($attributes);
        $note->save();

        return $note;
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function createVersion(array $attributes): ClinicalNoteVersion
    {
        return ClinicalNoteVersion::query()->create($attributes);
    }

    public function detail(ClinicalNote $note): ClinicalNote
    {
        return ClinicalNote::query()
            ->with([
                'encounter.patient',
                'encounter.provider',
                'encounter.encounterTemplate.encounterSections',
                'currentVersion.rawTranscript',
                'currentVersion.cleanedTranscript',
                'currentVersion.generatedBy',
                'currentVersion.signedBy',
                'versions.rawTranscript',
                'versions.cleanedTranscript',
                'versions.generatedBy',
                'versions.signedBy',
                'createdBy',
                'signedBy',
            ])
            ->whereKey($note->getKey())
            ->firstOrFail();
    }

    /**
     * @return Collection<int, ClinicalNoteVersion>
     */
    public function versions(ClinicalNote $note): Collection
    {
        return ClinicalNoteVersion::query()
            ->with(['rawTranscript', 'cleanedTranscript', 'generatedBy', 'signedBy'])
            ->where('clinical_note_id', $note->id)
            ->orderByDesc('version_number')
            ->get();
    }
}