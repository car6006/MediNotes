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
        Schema::create('visits', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('patient_id')->constrained('patients')->cascadeOnDelete();
            $table->foreignId('clinician_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignUuid('note_template_id')->nullable()->constrained('note_templates')->nullOnDelete();
            $table->string('encounter_type')->default('follow_up');
            $table->string('status')->default('draft');
            $table->text('chief_complaint')->nullable();
            $table->longText('conversation_summary')->nullable();
            $table->longText('subjective')->nullable();
            $table->longText('objective')->nullable();
            $table->longText('assessment')->nullable();
            $table->longText('plan')->nullable();
            $table->longText('patient_update')->nullable();
            $table->longText('transcript')->nullable();
            $table->json('template_snapshot')->nullable();
            $table->json('meta')->nullable();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('synced_at')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('visits');
    }
};
