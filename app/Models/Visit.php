<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Visit extends Encounter
{
    /** @use HasFactory<\Database\Factories\VisitFactory> */
    use HasFactory;

    public function template(): BelongsTo
    {
        return $this->belongsTo(NoteTemplate::class, 'note_template_id');
    }

    public function dictations(): HasMany
    {
        return $this->hasMany(Dictation::class)->latest();
    }
}
