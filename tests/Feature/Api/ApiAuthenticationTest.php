<?php

use App\Models\User;

it('requires authentication for protected clinical endpoints', function () {
    $this->getJson('/api/v1/patients')
        ->assertUnauthorized();
});

it('issues a sanctum token for clinical users and allows session introspection', function () {
    $user = User::factory()->create([
        'email' => 'clinician@example.com',
        'role' => 'clinician',
    ]);

    $loginResponse = $this->postJson('/api/v1/auth/login', [
        'email' => 'clinician@example.com',
        'password' => 'password',
        'device_name' => 'Pest Suite',
    ]);

    $loginResponse
        ->assertOk()
        ->assertJsonPath('data.user.email', 'clinician@example.com')
        ->assertJsonPath('data.security.audit_logging', true);

    $token = $loginResponse->json('data.token');

    $this->withHeader('Authorization', 'Bearer '.$token)
        ->getJson('/api/v1/auth/me')
        ->assertOk()
        ->assertJsonPath('data.user.role', 'clinician');

    $this->withHeader('Authorization', 'Bearer '.$token)
        ->postJson('/api/v1/auth/logout')
        ->assertOk();
});

it('denies clinical api access for accounts without an allowed role', function () {
    User::factory()->create([
        'email' => 'viewer@example.com',
        'role' => 'viewer',
    ]);

    $this->postJson('/api/v1/auth/login', [
        'email' => 'viewer@example.com',
        'password' => 'password',
    ])
        ->assertForbidden()
        ->assertJsonPath('message', 'Your account is not permitted to access the clinical API.');
});