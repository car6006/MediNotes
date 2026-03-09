<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class EncounterSection extends Model
{
    use HasFactory, HasUuids;

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'encounter_template_id',
        'key',
        'label',
        'position',
        'prompt',
        'is_required',
        'default_content',
        'meta',
    ];

    protected function casts(): array
    {
        return [
            'is_required' => 'boolean',
            'meta' => 'array',
        ];
    }

    public function encounterTemplate(): BelongsTo
    {
        return $this->belongsTo(EncounterTemplate::class);
    }
}