<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ClinicalNote extends Model
{
    use HasFactory, HasUuids;

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'encounter_id',
        'current_version_id',
        'current_version_number',
        'status',
        'note_format',
        'created_by_user_id',
        'signed_by_user_id',
        'signed_at',
        'meta',
    ];

    protected function casts(): array
    {
        return [
            'signed_at' => 'datetime',
            'meta' => 'array',
        ];
    }

    public function encounter(): BelongsTo
    {
        return $this->belongsTo(Encounter::class);
    }

    public function currentVersion(): BelongsTo
    {
        return $this->belongsTo(ClinicalNoteVersion::class, 'current_version_id');
    }

    public function versions(): HasMany
    {
        return $this->hasMany(ClinicalNoteVersion::class)->orderByDesc('version_number');
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    public function signedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'signed_by_user_id');
    }
}