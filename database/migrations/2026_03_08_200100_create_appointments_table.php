<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('appointments', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('clinic_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('patient_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('provider_id')->nullable()->constrained('providers')->nullOnDelete();
            $table->foreignId('booked_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('booking_type', 32)->default('returning_patient');
            $table->string('status', 32)->default('booked');
            $table->dateTime('scheduled_for');
            $table->unsignedSmallInteger('duration_minutes')->default(30);
            $table->string('reason_for_visit')->nullable();
            $table->text('notes')->nullable();
            $table->string('booking_channel', 32)->default('admin_capture');
            $table->dateTime('confirmed_at')->nullable();
            $table->dateTime('arrived_at')->nullable();
            $table->dateTime('in_consult_at')->nullable();
            $table->dateTime('completed_at')->nullable();
            $table->dateTime('cancelled_at')->nullable();
            $table->dateTime('no_show_at')->nullable();
            $table->text('cancellation_reason')->nullable();
            $table->json('metadata')->nullable();
            $table->timestamps();

            $table->index(['clinic_id', 'scheduled_for']);
            $table->index(['patient_id', 'scheduled_for']);
            $table->index(['provider_id', 'scheduled_for']);
            $table->index(['status', 'scheduled_for']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('appointments');
    }
};
