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
        Schema::create('dictations', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('visit_id')->constrained('visits')->cascadeOnDelete();
            $table->string('mode')->default('offline_whisper');
            $table->string('status')->default('queued');
            $table->string('locale', 16)->nullable();
            $table->string('audio_path')->nullable();
            $table->longText('transcript')->nullable();
            $table->longText('summary')->nullable();
            $table->boolean('processed_offline')->default(true);
            $table->unsignedInteger('duration_seconds')->nullable();
            $table->json('meta')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('dictations');
    }
};
