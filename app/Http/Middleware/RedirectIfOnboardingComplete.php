<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RedirectIfOnboardingComplete
{
    /**
     * Redirect users who have already finished onboarding away from the wizard.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user !== null && $user->hasCompletedOnboarding()) {
            return redirect()->route('dashboard');
        }

        return $next($request);
    }
}
