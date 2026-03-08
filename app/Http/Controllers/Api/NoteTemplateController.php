<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\SerializesClinicalPayloads;
use App\Http\Controllers\Controller;
use App\Models\NoteTemplate;
use App\Support\ClinicalAudit;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NoteTemplateController extends Controller
{
    use SerializesClinicalPayloads;

    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', NoteTemplate::class);

        $templates = NoteTemplate::query()
            ->latest('updated_at')
            ->get();

        ClinicalAudit::record(
            request: $request,
            event: 'template.list.viewed',
            context: [
                'results_count' => $templates->count(),
            ],
        );

        return response()->json([
            'data' => $templates->map(fn (NoteTemplate $template) => $this->templateData($template))->values(),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $this->authorize('create', NoteTemplate::class);

        $data = $this->validated($request);

        $template = NoteTemplate::query()->create([
            'id' => $data['id'] ?? (string) str()->uuid(),
            ...$this->payload($request, $data),
        ]);

        ClinicalAudit::record(
            request: $request,
            event: 'template.created',
            auditable: $template,
        );

        return response()->json([
            'data' => $this->templateData($template),
        ], 201);
    }

    public function upsert(Request $request, string $templateId): JsonResponse
    {
        $data = $this->validated($request);
        $existing = NoteTemplate::query()->find($templateId);

        $this->authorize($existing ? 'update' : 'create', $existing ?? NoteTemplate::class);

        $template = NoteTemplate::query()->updateOrCreate(
            ['id' => $templateId],
            $this->payload($request, $data),
        );

        ClinicalAudit::record(
            request: $request,
            event: $existing ? 'template.updated' : 'template.created',
            auditable: $template,
        );

        return response()->json([
            'data' => $this->templateData($template->fresh()),
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function validated(Request $request): array
    {
        return $request->validate([
            'id' => ['sometimes', 'uuid'],
            'title' => ['required', 'string', 'max:255'],
            'specialty' => ['nullable', 'string', 'max:255'],
            'template_body' => ['required', 'string'],
            'sections' => ['nullable', 'array'],
            'sections.*' => ['string', 'max:255'],
            'is_system' => ['nullable', 'boolean'],
            'created_by' => ['nullable', 'integer', 'exists:users,id'],
        ]);
    }

    /**
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    private function payload(Request $request, array $data): array
    {
        $user = $request->user();

        return [
            'title' => $data['title'],
            'specialty' => $data['specialty'] ?? null,
            'template_body' => $data['template_body'],
            'sections' => array_values($data['sections'] ?? []),
            'is_system' => (bool) ($data['is_system'] ?? false),
            'created_by' => $user && ! $user->hasRole('admin')
                ? $user->id
                : ($data['created_by'] ?? $user?->id),
        ];
    }
}
