<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('patient_consents', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('clinic_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('patient_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('appointment_id')->nullable()->constrained('appointments')->nullOnDelete();
            $table->foreignUuid('consent_template_id')->constrained()->cascadeOnDelete();
            $table->foreignId('captured_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('accepted_by');
            $table->string('source_channel', 32)->default('admin_capture');
            $table->dateTime('accepted_at');
            $table->string('template_version', 32);
            $table->json('template_snapshot')->nullable();
            $table->json('accepted_payload')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['patient_id', 'accepted_at']);
            $table->index(['appointment_id', 'accepted_at']);
            $table->index(['clinic_id', 'accepted_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('patient_consents');
    }
};
