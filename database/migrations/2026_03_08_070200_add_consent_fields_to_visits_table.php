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
        Schema::table('visits', function (Blueprint $table): void {
            $table->timestamp('privacy_notice_acknowledged_at')->nullable()->after('transcript');
            $table->timestamp('recording_consent_obtained_at')->nullable()->after('privacy_notice_acknowledged_at');
            $table->string('recording_consent_method', 255)->nullable()->after('recording_consent_obtained_at');
            $table->timestamp('ai_transcription_consent_obtained_at')->nullable()->after('recording_consent_method');
            $table->text('consent_notes')->nullable()->after('ai_transcription_consent_obtained_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('visits', function (Blueprint $table): void {
            $table->dropColumn([
                'privacy_notice_acknowledged_at',
                'recording_consent_obtained_at',
                'recording_consent_method',
                'ai_transcription_consent_obtained_at',
                'consent_notes',
            ]);
        });
    }
};
