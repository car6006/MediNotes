<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AudioFile extends Model
{
    use HasFactory, HasUuids;

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'encounter_id',
        'uploaded_by_user_id',
        'storage_disk',
        'storage_path',
        'original_filename',
        'mime_type',
        'file_size_bytes',
        'duration_seconds',
        'checksum_sha256',
        'capture_mode',
        'captured_at',
        'meta',
    ];

    protected function casts(): array
    {
        return [
            'file_size_bytes' => 'integer',
            'duration_seconds' => 'integer',
            'captured_at' => 'datetime',
            'meta' => 'array',
        ];
    }

    public function encounter(): BelongsTo
    {
        return $this->belongsTo(Encounter::class);
    }

    public function uploadedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'uploaded_by_user_id');
    }
}