<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Support\ClinicalAudit;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:255'],
        ]);

        $email = Str::lower($data['email']);
        $rateLimitKey = sprintf('api-login:%s|%s', $email, $request->ip());

        if (RateLimiter::tooManyAttempts($rateLimitKey, 5)) {
            return $this->privateJson([
                'message' => 'Too many login attempts. Please try again shortly.',
            ], 429);
        }

        /** @var User|null $user */
        $user = User::query()->where('email', $email)->first();

        if (! $user || ! Hash::check($data['password'], $user->password)) {
            RateLimiter::hit($rateLimitKey, 60);
            ClinicalAudit::authenticationFailure($request, [
                'email' => $email,
            ], $user);

            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        if (! $user->is_api_active || ! $user->canAccessClinicalApi()) {
            ClinicalAudit::record(
                request: $request,
                event: 'auth.login.denied',
                context: [
                    'email' => $email,
                    'role' => $user->primaryRoleSlug(),
                ],
                actor: $user,
            );

            return $this->privateJson([
                'message' => 'Your account is not permitted to access the clinical API.',
            ], 403);
        }

        RateLimiter::clear($rateLimitKey);

        $expirationMinutes = (int) config('sanctum.expiration', 480);
        $token = $user->createToken(
            name: $data['device_name'] ?? 'MediNotes Flutter Client',
            abilities: $user->tokenAbilities(),
            expiresAt: now()->addMinutes($expirationMinutes),
        );

        $user->forceFill([
            'last_api_login_at' => now(),
        ])->save();

        ClinicalAudit::record(
            request: $request,
            event: 'auth.login.succeeded',
            context: [
                'device_name' => $data['device_name'] ?? 'MediNotes Flutter Client',
                'token_expires_at' => $token->accessToken->expires_at?->toIso8601String(),
            ],
            actor: $user,
        );

        return $this->privateJson([
            'data' => [
                'token' => $token->plainTextToken,
                'expires_at' => $token->accessToken->expires_at?->toIso8601String(),
                'user' => $this->userData($user),
                'security' => [
                    'audit_logging' => true,
                    'encrypted_local_cache_required' => true,
                    'recording_requires_consent' => true,
                    'privacy_notice_version' => config('clinical.privacy_notice_version'),
                ],
            ],
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        ClinicalAudit::record(
            request: $request,
            event: 'auth.me.viewed',
            actor: $user,
        );

        return $this->privateJson([
            'data' => [
                'user' => $this->userData($user),
                'security' => [
                    'privacy_notice_version' => config('clinical.privacy_notice_version'),
                    'audit_logging' => true,
                ],
            ],
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $request->user()?->currentAccessToken()?->delete();

        ClinicalAudit::record(
            request: $request,
            event: 'auth.logout',
            actor: $user,
        );

        return $this->privateJson([
            'message' => 'Signed out successfully.',
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function userData(User $user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->primaryRoleSlug(),
            'roles' => $user->roles()->pluck('slug')->values()->all(),
            'is_api_active' => $user->is_api_active,
            'last_api_login_at' => $user->last_api_login_at?->toIso8601String(),
            'two_factor_enabled' => filled($user->two_factor_secret),
        ];
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    private function privateJson(array $payload, int $status = 200): JsonResponse
    {
        return response()->json($payload, $status, [
            'Cache-Control' => 'no-store, private',
            'Pragma' => 'no-cache',
        ]);
    }
}
