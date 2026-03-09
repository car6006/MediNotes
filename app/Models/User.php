<?php

namespace App\Models;

use App\Concerns\HasRolesAndPermissions;
// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Str;
use Laravel\Fortify\TwoFactorAuthenticatable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasApiTokens, HasFactory, HasRolesAndPermissions, Notifiable, TwoFactorAuthenticatable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'role',
        'password',
        'is_api_active',
        'last_api_login_at',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'two_factor_secret',
        'two_factor_recovery_codes',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'is_api_active' => 'boolean',
            'last_api_login_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    /**
     * Get the user's initials
     */
    public function initials(): string
    {
        return Str::of($this->name)
            ->explode(' ')
            ->take(2)
            ->map(fn ($word) => Str::substr($word, 0, 1))
            ->implode('');
    }

    public function visits(): HasMany
    {
        return $this->hasMany(Visit::class, 'clinician_id');
    }

    public function encounters(): HasMany
    {
        return $this->hasMany(Encounter::class, 'clinician_id');
    }

    public function auditLogs(): HasMany
    {
        return $this->hasMany(AuditLog::class);
    }

    public function providerProfile(): HasOne
    {
        return $this->hasOne(Provider::class);
    }

    public function bookedAppointments(): HasMany
    {
        return $this->hasMany(Appointment::class, 'booked_by_user_id')->latest('scheduled_for');
    }

    public function onboardingResponsesSubmitted(): HasMany
    {
        return $this->hasMany(OnboardingResponse::class, 'submitted_by_user_id')->latest('submitted_at');
    }

    public function capturedConsents(): HasMany
    {
        return $this->hasMany(PatientConsent::class, 'captured_by_user_id')->latest('accepted_at');
    }

    public function uploadedAudioFiles(): HasMany
    {
        return $this->hasMany(AudioFile::class, 'uploaded_by_user_id')->latest('captured_at');
    }

    public function generatedTranscripts(): HasMany
    {
        return $this->hasMany(Transcript::class, 'generated_by_user_id')->latest();
    }

    public function reviewedTranscripts(): HasMany
    {
        return $this->hasMany(Transcript::class, 'reviewed_by_user_id')->latest();
    }

    public function createdClinicalNotes(): HasMany
    {
        return $this->hasMany(ClinicalNote::class, 'created_by_user_id')->latest();
    }

    public function signedClinicalNotes(): HasMany
    {
        return $this->hasMany(ClinicalNote::class, 'signed_by_user_id')->latest();
    }
}
