<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('onboarding_responses', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('clinic_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('patient_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('appointment_id')->nullable()->constrained('appointments')->nullOnDelete();
            $table->foreignUuid('onboarding_form_id')->constrained()->cascadeOnDelete();
            $table->foreignId('submitted_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('source_channel', 32)->default('admin_capture');
            $table->json('responses');
            $table->dateTime('submitted_at');
            $table->timestamps();

            $table->index(['patient_id', 'submitted_at']);
            $table->index(['appointment_id', 'submitted_at']);
            $table->index(['clinic_id', 'submitted_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('onboarding_responses');
    }
};
