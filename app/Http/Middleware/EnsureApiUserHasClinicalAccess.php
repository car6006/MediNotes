<?php

namespace App\Http\Middleware;

use App\Support\ClinicalAudit;
use Closure;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureApiUserHasClinicalAccess
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        $tokenAllowsClinicalApi = ! $request->user() || $request->user()->tokenCan('clinical-api.access') || $request->user()->tokenCan('*');

        if (! $user || ! $user->is_api_active || ! $user->canAccessClinicalApi() || ! $tokenAllowsClinicalApi) {
            ClinicalAudit::record(
                request: $request,
                event: 'auth.api.denied',
                context: [
                    'email' => $user?->email,
                    'role' => $user?->primaryRoleSlug(),
                ],
                actor: $user,
            );

            return new JsonResponse([
                'message' => 'Your account is not permitted to access the clinical API.',
            ], 403, [
                'Cache-Control' => 'no-store, private',
            ]);
        }

        return $next($request);
    }
}
