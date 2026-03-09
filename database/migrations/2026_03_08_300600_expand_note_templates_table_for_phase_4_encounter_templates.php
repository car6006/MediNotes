<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('note_templates', function (Blueprint $table): void {
            $table->foreignUuid('clinic_id')->nullable()->after('id')->constrained()->nullOnDelete();
            $table->string('slug')->nullable()->after('title')->index();
            $table->string('version', 32)->default('1.0')->after('slug');
            $table->string('note_format', 32)->default('soap')->after('specialty');
            $table->longText('instructions')->nullable()->after('template_body');
            $table->boolean('is_active')->default(true)->after('is_system');
        });

        $templates = DB::table('note_templates')
            ->select('id', 'title')
            ->get();

        foreach ($templates as $template) {
            DB::table('note_templates')
                ->where('id', $template->id)
                ->update([
                    'slug' => Str::slug($template->title ?: 'template') ?: 'template',
                    'version' => '1.0',
                    'note_format' => 'soap',
                    'is_active' => true,
                ]);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('note_templates', function (Blueprint $table): void {
            $table->dropForeign(['clinic_id']);
            $table->dropIndex(['slug']);
            $table->dropColumn([
                'clinic_id',
                'slug',
                'version',
                'note_format',
                'instructions',
                'is_active',
            ]);
        });
    }
};