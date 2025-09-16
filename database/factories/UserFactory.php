<?php

namespace Database\Factories;

use App\Support\Onboarding;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\User>
 */
class UserFactory extends Factory
{
    /**
     * The current password being used by the factory.
     */
    protected static ?string $password;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'name' => fake()->name(),
            'email' => fake()->unique()->safeEmail(),
            'email_verified_at' => now(),
            'password' => static::$password ??= Hash::make('password'),
            'remember_token' => Str::random(10),
            'onboarding_step' => 1,
            'onboarding_state' => [
                'current_step' => 1,
                'completed' => [],
                'total' => Onboarding::totalSteps(),
            ],
            'onboarded_at' => null,
        ];
    }

    /**
     * Indicate that the model's email address should be unverified.
     */
    public function unverified(): static
    {
        return $this->state(fn (array $attributes) => [
            'email_verified_at' => null,
        ]);
    }

    /**
     * Mark the user as fully onboarded.
     */
    public function withOnboardingCompleted(): static
    {
        return $this->state(function (array $attributes) {
            $total = Onboarding::totalSteps();

            return [
                'onboarding_step' => $total,
                'onboarding_state' => [
                    'current_step' => $total,
                    'completed' => range(1, $total),
                    'total' => $total,
                ],
                'onboarded_at' => now(),
            ];
        });
    }
}
