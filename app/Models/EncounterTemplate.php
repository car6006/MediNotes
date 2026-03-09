<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class EncounterTemplate extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'note_templates';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'clinic_id',
        'title',
        'slug',
        'version',
        'specialty',
        'note_format',
        'template_body',
        'instructions',
        'sections',
        'is_system',
        'is_active',
        'created_by',
    ];

    protected function casts(): array
    {
        return [
            'sections' => 'array',
            'is_system' => 'boolean',
            'is_active' => 'boolean',
        ];
    }

    public function clinic(): BelongsTo
    {
        return $this->belongsTo(Clinic::class);
    }

    public function author(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function encounters(): HasMany
    {
        return $this->hasMany(Encounter::class, 'note_template_id')->latest('started_at');
    }

    public function visits(): HasMany
    {
        return $this->hasMany(Visit::class, 'note_template_id')->latest('started_at');
    }

    public function encounterSections(): HasMany
    {
        return $this->hasMany(EncounterSection::class, 'encounter_template_id')->orderBy('position');
    }
}