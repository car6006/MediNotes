<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Patient extends Model
{
    /** @use HasFactory<\Database\Factories\PatientFactory> */
    use HasFactory, HasUuids;

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'clinic_id',
        'medical_record_number',
        'title',
        'first_name',
        'middle_name',
        'last_name',
        'preferred_name',
        'date_of_birth',
        'sex',
        'phone',
        'alternate_phone',
        'email',
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
        'allergies',
        'allergies_summary',
        'medications',
        'medication_summary',
        'medical_history',
        'medical_history_summary',
        'notes',
        'alerts',
        'has_alerts',
        'last_visit_at',
    ];

    protected function casts(): array
    {
        return [
            'date_of_birth' => 'date',
            'allergies' => 'array',
            'medications' => 'array',
            'medical_history' => 'array',
            'alerts' => 'array',
            'has_alerts' => 'boolean',
            'last_visit_at' => 'datetime',
        ];
    }

    public function clinic(): BelongsTo
    {
        return $this->belongsTo(Clinic::class);
    }

    public function visits(): HasMany
    {
        return $this->hasMany(Visit::class)->latest('started_at');
    }

    public function encounters(): HasMany
    {
        return $this->hasMany(Encounter::class)->latest('started_at');
    }

    public function appointments(): HasMany
    {
        return $this->hasMany(Appointment::class)->latest('scheduled_for');
    }

    public function onboardingResponses(): HasMany
    {
        return $this->hasMany(OnboardingResponse::class)->latest('submitted_at');
    }

    public function consents(): HasMany
    {
        return $this->hasMany(PatientConsent::class)->latest('accepted_at');
    }

    public function getFullNameAttribute(): string
    {
        return trim("{$this->first_name} {$this->last_name}");
    }
}
