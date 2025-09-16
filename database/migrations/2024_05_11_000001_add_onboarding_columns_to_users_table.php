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
        Schema::table('users', function (Blueprint $table) {
            $table->unsignedTinyInteger('onboarding_step')->default(1)->after('remember_token');
            $table->json('onboarding_state')->nullable()->after('onboarding_step');
            $table->timestamp('onboarded_at')->nullable()->after('onboarding_state');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'onboarding_step',
                'onboarding_state',
                'onboarded_at',
            ]);
        });
    }
};
