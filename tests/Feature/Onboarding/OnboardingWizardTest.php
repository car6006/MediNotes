<?php

use App\Models\User;
use App\Support\Onboarding;
use Livewire\Volt\Volt as LivewireVolt;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

test('unverified users are redirected to the verification notice before onboarding', function () {
    $user = User::factory()->unverified()->create();

    $this->actingAs($user);

    $response = $this->get(route('onboarding.wizard'));

    $response->assertRedirect(route('verification.notice'));
});

test('verified users who are not onboarded can view the wizard', function () {
    $user = User::factory()->create([
        'email_verified_at' => now(),
        'onboarded_at' => null,
    ]);

    $this->actingAs($user);

    $response = $this->get(route('onboarding.wizard'));

    $response->assertOk();
});

test('wizard progress persists to the user record', function () {
    $user = User::factory()->create([
        'email_verified_at' => now(),
        'onboarded_at' => null,
    ]);

    $this->actingAs($user);

    LivewireVolt::test('onboarding.wizard')
        ->call('nextStep');

    $user->refresh();

    expect($user->onboarding_step)->toBe(2);
    expect($user->onboarding_state['current_step'] ?? null)->toBe(2);
    expect($user->onboarding_state['completed'] ?? [])->toContain(1);
    expect($user->onboarded_at)->toBeNull();
});

test('completing the wizard marks the user as onboarded', function () {
    $user = User::factory()->create([
        'email_verified_at' => now(),
        'onboarded_at' => null,
    ]);

    $this->actingAs($user);

    $component = LivewireVolt::test('onboarding.wizard');

    $totalSteps = Onboarding::totalSteps();

    $component
        ->call('goToStep', $totalSteps)
        ->call('complete')
        ->assertRedirect(route('dashboard', absolute: false));

    $user->refresh();

    expect($user->hasCompletedOnboarding())->toBeTrue();
    expect($user->onboarding_step)->toBe($totalSteps);
    expect($user->onboarding_state['completed'] ?? [])->toEqual(range(1, $totalSteps));
});
