<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('audio_files', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('encounter_id')->constrained('visits')->cascadeOnDelete();
            $table->foreignId('uploaded_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('storage_disk', 64)->default('private');
            $table->string('storage_path');
            $table->string('original_filename')->nullable();
            $table->string('mime_type', 128)->nullable();
            $table->unsignedBigInteger('file_size_bytes')->nullable();
            $table->unsignedInteger('duration_seconds')->nullable();
            $table->string('checksum_sha256', 64)->nullable()->index();
            $table->string('capture_mode', 64)->default('offline_whisper');
            $table->timestamp('captured_at')->nullable();
            $table->json('meta')->nullable();
            $table->timestamps();

            $table->index(['encounter_id', 'captured_at'], 'audio_files_encounter_captured_index');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('audio_files');
    }
};