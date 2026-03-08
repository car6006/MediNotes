<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Appointment extends Model
{
    use HasFactory, HasUuids;

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'clinic_id',
        'patient_id',
        'provider_id',
        'booked_by_user_id',
        'booking_type',
        'status',
        'scheduled_for',
        'duration_minutes',
        'reason_for_visit',
        'notes',
        'booking_channel',
        'confirmed_at',
        'arrived_at',
        'in_consult_at',
        'completed_at',
        'cancelled_at',
        'no_show_at',
        'cancellation_reason',
        'metadata',
    ];

    protected function casts(): array
    {
        return [
            'scheduled_for' => 'datetime',
            'confirmed_at' => 'datetime',
            'arrived_at' => 'datetime',
            'in_consult_at' => 'datetime',
            'completed_at' => 'datetime',
            'cancelled_at' => 'datetime',
            'no_show_at' => 'datetime',
            'metadata' => 'array',
        ];
    }

    public function clinic(): BelongsTo
    {
        return $this->belongsTo(Clinic::class);
    }

    public function patient(): BelongsTo
    {
        return $this->belongsTo(Patient::class);
    }

    public function provider(): BelongsTo
    {
        return $this->belongsTo(Provider::class);
    }

    public function bookedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'booked_by_user_id');
    }

    public function onboardingResponses(): HasMany
    {
        return $this->hasMany(OnboardingResponse::class)->latest('submitted_at');
    }

    public function consents(): HasMany
    {
        return $this->hasMany(PatientConsent::class)->latest('accepted_at');
    }
}
