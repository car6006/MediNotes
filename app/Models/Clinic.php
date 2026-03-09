<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Clinic extends Model
{
    /** @use HasFactory<\Database\Factories\ClinicFactory> */
    use HasFactory, HasUuids;

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'name',
        'slug',
        'registration_number',
        'phone',
        'email',
        'timezone',
        'settings',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'settings' => 'array',
            'is_active' => 'boolean',
        ];
    }

    public function providers(): HasMany
    {
        return $this->hasMany(Provider::class);
    }

    public function patients(): HasMany
    {
        return $this->hasMany(Patient::class);
    }

    public function encounters(): HasMany
    {
        return $this->hasMany(Encounter::class)->latest('started_at');
    }

    public function appointments(): HasMany
    {
        return $this->hasMany(Appointment::class)->latest('scheduled_for');
    }

    public function onboardingForms(): HasMany
    {
        return $this->hasMany(OnboardingForm::class)->latest('updated_at');
    }

    public function onboardingResponses(): HasMany
    {
        return $this->hasMany(OnboardingResponse::class)->latest('submitted_at');
    }

    public function consentTemplates(): HasMany
    {
        return $this->hasMany(ConsentTemplate::class)->latest('updated_at');
    }

    public function patientConsents(): HasMany
    {
        return $this->hasMany(PatientConsent::class)->latest('accepted_at');
    }

    public function encounterTemplates(): HasMany
    {
        return $this->hasMany(EncounterTemplate::class)->latest('updated_at');
    }
}
