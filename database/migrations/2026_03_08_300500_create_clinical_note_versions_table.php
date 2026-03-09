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
        Schema::create('clinical_note_versions', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('clinical_note_id')->constrained('clinical_notes')->cascadeOnDelete();
            $table->foreignUuid('encounter_id')->constrained('visits')->cascadeOnDelete();
            $table->unsignedInteger('version_number');
            $table->string('source', 64)->default('manual_edit');
            $table->json('sections_json');
            $table->foreignUuid('raw_transcript_id')->nullable()->constrained('transcripts')->nullOnDelete();
            $table->foreignUuid('cleaned_transcript_id')->nullable()->constrained('transcripts')->nullOnDelete();
            $table->foreignId('generated_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('signed_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('signed_at')->nullable();
            $table->boolean('is_locked')->default(false);
            $table->text('change_summary')->nullable();
            $table->json('meta')->nullable();
            $table->timestamps();

            $table->unique(['clinical_note_id', 'version_number'], 'clinical_note_versions_note_version_unique');
            $table->index(['encounter_id', 'created_at'], 'clinical_note_versions_encounter_created_index');
        });

        Schema::table('clinical_notes', function (Blueprint $table): void {
            $table->foreign('current_version_id')
                ->references('id')
                ->on('clinical_note_versions')
                ->nullOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('clinical_notes', function (Blueprint $table): void {
            $table->dropForeign(['current_version_id']);
        });

        Schema::dropIfExists('clinical_note_versions');
    }
};