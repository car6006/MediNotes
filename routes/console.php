<?php

use App\Models\User;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\URL;
use Symfony\Component\Console\Command\Command as ConsoleCommand;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Artisan::command('user:verification-link {user : The user ID or email address}', function (string $identifier) {
    $user = User::query()
        ->when(
            is_numeric($identifier),
            fn ($query) => $query->whereKey((int) $identifier),
            fn ($query) => $query->where('email', $identifier)
        )
        ->first();

    if ($user === null) {
        $this->error("Unable to find a user matching [{$identifier}].");

        return ConsoleCommand::FAILURE;
    }

    $minutes = (int) $this->option('minutes');

    if ($minutes <= 0) {
        $this->warn('Expiration must be greater than zero minutes. Defaulting to 60 minutes.');

        $minutes = 60;
    }

    $signedUrl = URL::temporarySignedRoute(
        'verification.verify',
        now()->addMinutes($minutes),
        [
            'id' => $user->getKey(),
            'hash' => sha1($user->getEmailForVerification()),
        ]
    );

    $this->info('Temporary verification link generated successfully:');
    $this->line($signedUrl);

    return ConsoleCommand::SUCCESS;
})->purpose('Create a temporary signed email verification URL')
    ->addOption('minutes', null, \Symfony\Component\Console\Input\InputOption::VALUE_OPTIONAL, 'Minutes until the link expires', 60);

Artisan::command('user:verify {user : The user ID or email address}', function (string $identifier) {
    $user = User::query()
        ->when(
            is_numeric($identifier),
            fn ($query) => $query->whereKey((int) $identifier),
            fn ($query) => $query->where('email', $identifier)
        )
        ->first();

    if ($user === null) {
        $this->error("Unable to find a user matching [{$identifier}].");

        return ConsoleCommand::FAILURE;
    }

    if ($user->hasVerifiedEmail()) {
        $this->comment(sprintf('User %s is already verified.', $user->email));
    } else {
        $user->markEmailAsVerified();
        $this->info(sprintf('Marked %s as verified.', $user->email));
    }

    $user->initializeOnboardingState();
    $user->refresh();

    $this->line(sprintf('Verified at: %s', optional($user->email_verified_at)->toDateTimeString() ?? '—'));
    $this->line(sprintf('Onboarding step: %s', $user->onboarding_step ?? '—'));
    $this->line(sprintf(
        'Next route: %s',
        $user->hasCompletedOnboarding() ? route('dashboard', absolute: false) : route('onboarding.wizard', absolute: false)
    ));

    return ConsoleCommand::SUCCESS;
})->purpose('Mark a user as email verified and sync onboarding state');
