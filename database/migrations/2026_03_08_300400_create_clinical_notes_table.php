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
        Schema::create('clinical_notes', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('encounter_id')->unique()->constrained('visits')->cascadeOnDelete();
            $table->string('note_format', 32)->default('soap');
            $table->string('status', 32)->default('draft');
            $table->uuid('current_version_id')->nullable();
            $table->unsignedInteger('current_version_number')->default(0);
            $table->foreignId('created_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('signed_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('signed_at')->nullable();
            $table->json('meta')->nullable();
            $table->timestamps();

            $table->index(['status', 'updated_at'], 'clinical_notes_status_updated_index');
        });

        Schema::table('visits', function (Blueprint $table): void {
            $table->foreign('current_clinical_note_id')
                ->references('id')
                ->on('clinical_notes')
                ->nullOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('visits', function (Blueprint $table): void {
            $table->dropForeign(['current_clinical_note_id']);
        });

        Schema::dropIfExists('clinical_notes');
    }
};