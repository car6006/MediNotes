<?php

use App\Models\User;
use Symfony\Component\Console\Command\Command as ConsoleCommand;
use function Pest\Laravel\artisan;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

it('generates a temporary verification link without sending email', function () {
    config()->set('app.url', 'https://medinotes.test');

    $user = User::factory()->unverified()->create();

    artisan('user:verification-link', ['user' => $user->email])
        ->expectsOutputToContain('Temporary verification link generated successfully:')
        ->expectsOutputToContain('/verify-email/'.$user->getKey())
        ->assertExitCode(ConsoleCommand::SUCCESS);
});

it('marks a user as verified through the console command', function () {
    $user = User::factory()->unverified()->createQuietly([
        'onboarding_step' => null,
        'onboarding_state' => null,
        'onboarded_at' => null,
    ]);

    expect($user->hasVerifiedEmail())->toBeFalse();

    artisan('user:verify', ['user' => $user->id])
        ->expectsOutputToContain(sprintf('Marked %s as verified.', $user->email))
        ->expectsOutputToContain('Onboarding step:')
        ->assertExitCode(ConsoleCommand::SUCCESS);

    $user->refresh();

    expect($user->hasVerifiedEmail())->toBeTrue();
    expect($user->onboarding_state)->not()->toBeNull();
    expect($user->onboarding_step)->toBe(1);
});
