<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;

class NoteTemplate extends EncounterTemplate
{
    /** @use HasFactory<\Database\Factories\NoteTemplateFactory> */
    use HasFactory;

    public function visits(): HasMany
    {
        return $this->hasMany(Visit::class, 'note_template_id');
    }
}
