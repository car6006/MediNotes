<?php

use App\Models\User;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

test('guests are redirected to the login page', function () {
    $response = $this->get('/dashboard');
    $response->assertRedirect('/login');
});

test('authenticated users who have not finished onboarding are redirected to the wizard', function () {
    $user = User::factory()->create([
        'onboarded_at' => null,
    ]);

    $this->actingAs($user);

    $response = $this->get('/dashboard');

    $response->assertRedirect(route('onboarding.wizard'));
});

test('onboarded users can visit the dashboard', function () {
    $user = User::factory()->withOnboardingCompleted()->create();
    $this->actingAs($user);

    $response = $this->get('/dashboard');
    $response->assertStatus(200);
});