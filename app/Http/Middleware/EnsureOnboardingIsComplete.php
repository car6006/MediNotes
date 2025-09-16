<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureOnboardingIsComplete
{
    /**
     * Redirect users who have not finished onboarding.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user !== null && ! $user->hasCompletedOnboarding()) {
            return redirect()->route('onboarding.wizard');
        }

        return $next($request);
    }
}
