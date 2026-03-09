<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Templates\ListEncounterTemplatesRequest;
use App\Http\Requests\Templates\StoreEncounterTemplateRequest;
use App\Http\Requests\Templates\UpdateEncounterTemplateRequest;
use App\Http\Resources\Templates\EncounterTemplateResource;
use App\Models\EncounterTemplate;
use App\Services\EncounterTemplateService;
use App\Support\ClinicalAudit;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class EncounterTemplateController extends Controller
{
    public function __construct(
        private readonly EncounterTemplateService $templates,
    ) {
    }

    public function index(ListEncounterTemplatesRequest $request): AnonymousResourceCollection
    {
        $this->authorize('viewAny', EncounterTemplate::class);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $templates = $this->templates->list($user, $request->validated());

        ClinicalAudit::record(
            request: $request,
            event: 'encounter_template.listed',
            context: [
                'filters' => $request->validated(),
                'results_count' => $templates->count(),
            ],
        );

        return EncounterTemplateResource::collection($templates);
    }

    public function show(Request $request, EncounterTemplate $encounterTemplate): EncounterTemplateResource
    {
        $this->authorize('view', $encounterTemplate);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $template = $this->templates->detail($user, $encounterTemplate);

        ClinicalAudit::record(
            request: $request,
            event: 'encounter_template.viewed',
            auditable: $template,
        );

        return new EncounterTemplateResource($template);
    }

    public function store(StoreEncounterTemplateRequest $request): JsonResponse
    {
        $this->authorize('create', EncounterTemplate::class);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $template = $this->templates->create($user, $request->validated());

        ClinicalAudit::record(
            request: $request,
            event: 'encounter_template.created',
            auditable: $template,
        );

        return (new EncounterTemplateResource($template))
            ->response()
            ->setStatusCode(201);
    }

    public function update(UpdateEncounterTemplateRequest $request, EncounterTemplate $encounterTemplate): JsonResponse
    {
        $this->authorize('update', $encounterTemplate);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $template = $this->templates->update($user, $encounterTemplate, $request->validated());

        ClinicalAudit::record(
            request: $request,
            event: 'encounter_template.updated',
            auditable: $template,
        );

        return (new EncounterTemplateResource($template))->response();
    }
}
