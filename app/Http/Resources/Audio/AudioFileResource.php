<?php

namespace App\Http\Resources\Audio;

use App\Models\AudioFile;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin AudioFile */
class AudioFileResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'encounter_id' => $this->encounter_id,
            'storage_disk' => $this->storage_disk,
            'storage_path' => $this->storage_path,
            'original_filename' => $this->original_filename,
            'mime_type' => $this->mime_type,
            'file_size_bytes' => $this->file_size_bytes,
            'duration_seconds' => $this->duration_seconds,
            'checksum_sha256' => $this->checksum_sha256,
            'capture_mode' => $this->capture_mode,
            'captured_at' => $this->captured_at?->toIso8601String(),
            'meta' => $this->meta ?? [],
            'uploaded_by' => $this->uploadedBy ? [
                'id' => $this->uploadedBy->id,
                'name' => $this->uploadedBy->name,
                'email' => $this->uploadedBy->email,
            ] : null,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
