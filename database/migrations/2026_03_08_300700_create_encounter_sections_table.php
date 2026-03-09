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
        Schema::create('encounter_sections', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('encounter_template_id')->constrained('note_templates')->cascadeOnDelete();
            $table->string('key', 64);
            $table->string('label');
            $table->unsignedInteger('position')->default(1);
            $table->text('prompt')->nullable();
            $table->boolean('is_required')->default(false);
            $table->longText('default_content')->nullable();
            $table->json('meta')->nullable();
            $table->timestamps();

            $table->unique(['encounter_template_id', 'key'], 'encounter_sections_template_key_unique');
            $table->index(['encounter_template_id', 'position'], 'encounter_sections_template_position_index');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('encounter_sections');
    }
};