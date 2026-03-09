<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('visits', function (Blueprint $table): void {
            $table->foreignUuid('clinic_id')->nullable()->after('patient_id')->constrained()->nullOnDelete();
            $table->foreignUuid('appointment_id')->nullable()->after('clinic_id')->constrained()->nullOnDelete();
            $table->foreignUuid('provider_id')->nullable()->after('clinician_id')->constrained()->nullOnDelete();
            $table->uuid('current_clinical_note_id')->nullable()->after('provider_id');
            $table->timestamp('status_changed_at')->nullable()->after('status');
            $table->timestamp('in_progress_at')->nullable()->after('status_changed_at');
            $table->timestamp('dictation_captured_at')->nullable()->after('started_at');
            $table->timestamp('transcription_pending_at')->nullable()->after('dictation_captured_at');
            $table->timestamp('draft_note_ready_at')->nullable()->after('transcription_pending_at');
            $table->timestamp('doctor_review_pending_at')->nullable()->after('draft_note_ready_at');
            $table->timestamp('signed_off_at')->nullable()->after('doctor_review_pending_at');
            $table->index(['clinic_id', 'status', 'started_at'], 'visits_clinic_status_started_index');
        });

        $visits = DB::table('visits')
            ->select('id', 'patient_id')
            ->get();

        foreach ($visits as $visit) {
            $clinicId = DB::table('patients')
                ->where('id', $visit->patient_id)
                ->value('clinic_id');

            DB::table('visits')
                ->where('id', $visit->id)
                ->update([
                    'clinic_id' => $clinicId,
                ]);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('visits', function (Blueprint $table): void {
            $table->dropIndex('visits_clinic_status_started_index');
            $table->dropForeign(['clinic_id']);
            $table->dropForeign(['appointment_id']);
            $table->dropForeign(['provider_id']);
            $table->dropColumn([
                'clinic_id',
                'appointment_id',
                'provider_id',
                'current_clinical_note_id',
                'status_changed_at',
                'in_progress_at',
                'dictation_captured_at',
                'transcription_pending_at',
                'draft_note_ready_at',
                'doctor_review_pending_at',
                'signed_off_at',
            ]);
        });
    }
};