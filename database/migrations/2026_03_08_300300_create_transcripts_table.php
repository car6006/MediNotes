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
        Schema::create('transcripts', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('encounter_id')->constrained('visits')->cascadeOnDelete();
            $table->foreignUuid('audio_file_id')->nullable()->constrained('audio_files')->nullOnDelete();
            $table->string('transcript_type', 32)->index();
            $table->string('source_engine', 64)->default('offline_whisper');
            $table->longText('content');
            $table->string('language', 16)->nullable();
            $table->decimal('confidence', 5, 2)->nullable();
            $table->foreignId('generated_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('reviewed_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable();
            $table->json('meta')->nullable();
            $table->timestamps();

            $table->index(['encounter_id', 'transcript_type', 'created_at'], 'transcripts_encounter_type_created_index');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('transcripts');
    }
};