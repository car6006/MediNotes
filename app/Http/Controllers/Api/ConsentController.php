<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Consents\ListConsentTemplatesRequest;
use App\Http\Requests\Consents\StorePatientConsentRequest;
use App\Http\Resources\Consents\ConsentTemplateResource;
use App\Http\Resources\Consents\PatientConsentResource;
use App\Models\ConsentTemplate;
use App\Models\Patient;
use App\Models\PatientConsent;
use App\Services\ConsentService;
use App\Support\ClinicalAudit;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class ConsentController extends Controller
{
    public function __construct(
        private readonly ConsentService $consents,
    ) {
    }

    public function templates(ListConsentTemplatesRequest $request): AnonymousResourceCollection
    {
        $this->authorize('viewAny', ConsentTemplate::class);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $templates = $this->consents->listTemplates(
            $user,
            $request->validated('clinic_id'),
            $request->validated('consent_type'),
            $request->boolean('is_active', true),
        );

        ClinicalAudit::record(
            request: $request,
            event: 'consent.templates.viewed',
            context: [
                'count' => $templates->count(),
                'clinic_id' => $request->validated('clinic_id'),
                'consent_type' => $request->validated('consent_type'),
            ],
        );

        return ConsentTemplateResource::collection($templates)->additional([
            'meta' => [
                'count' => $templates->count(),
            ],
        ]);
    }

    public function store(StorePatientConsentRequest $request): JsonResponse
    {
        $this->authorize('create', PatientConsent::class);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $consent = $this->consents->capture($user, $request->validated());

        ClinicalAudit::record(
            request: $request,
            event: 'patient.consent.captured',
            auditable: $consent,
            patientId: $consent->patient_id,
            context: [
                'appointment_id' => $consent->appointment_id,
                'consent_template_id' => $consent->consent_template_id,
                'template_version' => $consent->template_version,
            ],
        );

        return (new PatientConsentResource($consent))
            ->response()
            ->setStatusCode(201);
    }

    public function patientConsents(Request $request, Patient $patient): AnonymousResourceCollection
    {
        $this->authorize('view', $patient);
        $this->authorize('viewAny', PatientConsent::class);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $consents = $this->consents->patientConsents($user, $patient);

        ClinicalAudit::record(
            request: $request,
            event: 'patient.consents.viewed',
            auditable: $patient,
            context: [
                'count' => $consents->count(),
            ],
            patientId: $patient->id,
        );

        return PatientConsentResource::collection($consents)->additional([
            'meta' => [
                'patient_id' => $patient->id,
                'count' => $consents->count(),
            ],
        ]);
    }
}
