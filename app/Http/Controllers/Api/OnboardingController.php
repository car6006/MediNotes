<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Onboarding\ListOnboardingFormsRequest;
use App\Http\Requests\Onboarding\StoreOnboardingResponseRequest;
use App\Http\Resources\Onboarding\OnboardingFormResource;
use App\Http\Resources\Onboarding\OnboardingResponseResource;
use App\Models\OnboardingForm;
use App\Models\OnboardingResponse;
use App\Models\Patient;
use App\Services\OnboardingService;
use App\Support\ClinicalAudit;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class OnboardingController extends Controller
{
    public function __construct(
        private readonly OnboardingService $onboarding,
    ) {
    }

    public function forms(ListOnboardingFormsRequest $request): AnonymousResourceCollection
    {
        $this->authorize('viewAny', OnboardingForm::class);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $forms = $this->onboarding->listForms(
            $user,
            $request->validated('clinic_id'),
            $request->boolean('is_active', true),
        );

        ClinicalAudit::record(
            request: $request,
            event: 'onboarding.forms.viewed',
            context: [
                'count' => $forms->count(),
                'clinic_id' => $request->validated('clinic_id'),
            ],
        );

        return OnboardingFormResource::collection($forms)->additional([
            'meta' => [
                'count' => $forms->count(),
            ],
        ]);
    }

    public function storeResponse(StoreOnboardingResponseRequest $request): JsonResponse
    {
        $this->authorize('create', OnboardingResponse::class);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $response = $this->onboarding->submit($user, $request->validated());

        ClinicalAudit::record(
            request: $request,
            event: 'onboarding.response.submitted',
            auditable: $response,
            patientId: $response->patient_id,
            context: [
                'appointment_id' => $response->appointment_id,
                'onboarding_form_id' => $response->onboarding_form_id,
            ],
        );

        return (new OnboardingResponseResource($response))
            ->response()
            ->setStatusCode(201);
    }

    public function patientOnboarding(Request $request, Patient $patient): AnonymousResourceCollection
    {
        $this->authorize('view', $patient);
        $this->authorize('viewAny', OnboardingResponse::class);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $responses = $this->onboarding->patientResponses($user, $patient);

        ClinicalAudit::record(
            request: $request,
            event: 'patient.onboarding.viewed',
            auditable: $patient,
            context: [
                'count' => $responses->count(),
            ],
            patientId: $patient->id,
        );

        return OnboardingResponseResource::collection($responses)->additional([
            'meta' => [
                'patient_id' => $patient->id,
                'count' => $responses->count(),
            ],
        ]);
    }
}
