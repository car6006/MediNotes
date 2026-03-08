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
        Schema::table('patients', function (Blueprint $table): void {
            $table->foreignUuid('clinic_id')->nullable()->after('id')->constrained()->nullOnDelete();
            $table->string('title', 32)->nullable()->after('medical_record_number');
            $table->string('middle_name')->nullable()->after('first_name');
            $table->string('preferred_name')->nullable()->after('middle_name');
            $table->string('alternate_phone')->nullable()->after('phone');
            $table->string('national_id_number')->nullable()->after('email')->index();
            $table->string('passport_number')->nullable()->after('national_id_number')->index();
            $table->string('external_reference')->nullable()->after('passport_number')->index();
            $table->string('address_line_1')->nullable()->after('external_reference');
            $table->string('address_line_2')->nullable()->after('address_line_1');
            $table->string('city')->nullable()->after('address_line_2');
            $table->string('province')->nullable()->after('city');
            $table->string('postal_code', 32)->nullable()->after('province');
            $table->string('country', 2)->default('ZA')->after('postal_code');
            $table->string('emergency_contact_name')->nullable()->after('country');
            $table->string('emergency_contact_phone')->nullable()->after('emergency_contact_name');
            $table->longText('medical_history_summary')->nullable()->after('medical_history');
            $table->longText('allergies_summary')->nullable()->after('allergies');
            $table->longText('medication_summary')->nullable()->after('medications');
            $table->json('alerts')->nullable()->after('notes');
            $table->boolean('has_alerts')->default(false)->after('alerts');
            $table->index(['clinic_id', 'last_name', 'first_name'], 'patients_clinic_name_index');
        });

        $defaultClinicId = DB::table('clinics')->orderBy('created_at')->value('id');

        $patients = DB::table('patients')
            ->select('id', 'medical_history', 'allergies', 'medications')
            ->get();

        foreach ($patients as $patient) {
            DB::table('patients')
                ->where('id', $patient->id)
                ->update([
                    'clinic_id' => $defaultClinicId,
                    'medical_history_summary' => $this->summaryFromJson($patient->medical_history),
                    'allergies_summary' => $this->summaryFromJson($patient->allergies),
                    'medication_summary' => $this->summaryFromJson($patient->medications),
                    'has_alerts' => false,
                ]);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('patients', function (Blueprint $table): void {
            $table->dropIndex('patients_clinic_name_index');
            $table->dropIndex(['national_id_number']);
            $table->dropIndex(['passport_number']);
            $table->dropIndex(['external_reference']);
            $table->dropForeign(['clinic_id']);
            $table->dropColumn([
                'clinic_id',
                'title',
                'middle_name',
                'preferred_name',
                'alternate_phone',
                'national_id_number',
                'passport_number',
                'external_reference',
                'address_line_1',
                'address_line_2',
                'city',
                'province',
                'postal_code',
                'country',
                'emergency_contact_name',
                'emergency_contact_phone',
                'medical_history_summary',
                'allergies_summary',
                'medication_summary',
                'alerts',
                'has_alerts',
            ]);
        });
    }

    private function summaryFromJson(mixed $value): ?string
    {
        if ($value === null) {
            return null;
        }

        $items = json_decode((string) $value, true);

        if (! is_array($items)) {
            return null;
        }

        $items = array_values(array_filter(array_map(static fn (mixed $item): string => trim((string) $item), $items)));

        return $items === [] ? null : implode('; ', $items);
    }
};
