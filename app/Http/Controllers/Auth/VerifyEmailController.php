<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use Illuminate\Foundation\Auth\EmailVerificationRequest;
use Illuminate\Http\RedirectResponse;

class VerifyEmailController extends Controller
{
    /**
     * Mark the authenticated user's email address as verified.
     */
    public function __invoke(EmailVerificationRequest $request): RedirectResponse
    {
        $user = $request->user();

        if (! $user->hasVerifiedEmail()) {
            $request->fulfill();
        }

        $user->initializeOnboardingState();

        $destination = $user->hasCompletedOnboarding() ? 'dashboard' : 'onboarding.wizard';

        return redirect()->intended(route($destination, absolute: false).'?verified=1');
    }
}
