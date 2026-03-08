<?php

namespace App\Support;

use App\Models\AuditLog;
use App\Models\Patient;
use App\Models\User;
use App\Models\Visit;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;

class ClinicalAudit
{
    /**
     * @param  array<string, mixed>  $context
     */
    public static function record(
        Request $request,
        string $event,
        ?Model $auditable = null,
        array $context = [],
        ?User $actor = null,
        ?string $patientId = null,
    ): void {
        $user = $actor ?? $request->user();

        if ($auditable instanceof Patient) {
            $patientId = $auditable->getKey();
        }

        if ($auditable instanceof Visit) {
            $patientId ??= $auditable->patient_id;
        }

        AuditLog::query()->create([
            'user_id' => $user?->id,
            'patient_id' => $patientId,
            'event' => $event,
            'auditable_type' => $auditable?->getMorphClass(),
            'auditable_id' => $auditable?->getKey(),
            'ip_address' => $request->ip(),
            'user_agent' => substr((string) $request->userAgent(), 0, 1024),
            'context' => $context,
            'occurred_at' => now(),
        ]);
    }

    /**
     * @param  array<string, mixed>  $context
     */
    public static function authenticationFailure(
        Request $request,
        array $context = [],
        ?User $actor = null,
    ): void {
        static::record(
            request: $request,
            event: 'auth.login.failed',
            auditable: null,
            context: $context,
            actor: $actor,
        );
    }
}
