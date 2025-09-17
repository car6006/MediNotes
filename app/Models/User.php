<?php

namespace App\Models;

use App\Support\Onboarding;
use Illuminate\Auth\MustVerifyEmail as MustVerifyEmailTrait;
use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Str;

class User extends Authenticatable implements MustVerifyEmail
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasFactory, MustVerifyEmailTrait, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'onboarding_step',
        'onboarding_state',
        'onboarded_at',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
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
            'password' => 'hashed',
            'onboarding_state' => 'array',
            'onboarded_at' => 'datetime',
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

    /**
     * Determine if the user has finished onboarding.
     */
    public function hasCompletedOnboarding(): bool
    {
        return $this->onboarded_at !== null;
    }

    /**
     * Initialize the onboarding state for a newly created user.
     */
    public function initializeOnboardingState(): void
    {
        if ($this->onboarding_state !== null) {
            return;
        }

        $defaultStep = 1;

        $this->forceFill([
            'onboarding_step' => $defaultStep,
            'onboarding_state' => [
                'current_step' => $defaultStep,
                'completed' => [],
                'total' => Onboarding::totalSteps(),
            ],
        ])->save();
    }

    /**
     * Boot the model and configure onboarding defaults.
     */
    protected static function booted(): void
    {
        static::created(function (self $user): void {
            $user->initializeOnboardingState();
            // Automatically verify email in local/dev environment
            if (app()->environment('local')) {
                $user->email_verified_at = now();
                $user->save();
            }
        });
    }

    /**
     * Always treat email as verified in local environment.
     */
    public function hasVerifiedEmail(): bool
    {
        if (app()->environment('local')) {
            return true;
        }
        return !is_null($this->email_verified_at);
    }
}
