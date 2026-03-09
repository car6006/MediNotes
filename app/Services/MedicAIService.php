<?php

namespace App\Services;

use Throwable;

class MedicAIService
{
    public function __construct(
        private readonly ?string $apiKey = null,
        private readonly ?string $baseUrl = null,
        private readonly ?int $timeout = null,
    ) {
    }

    public static function fromConfig(): self
    {
        return new self(
            apiKey: config('medicai.api_key'),
            baseUrl: config('medicai.base_url'),
            timeout: (int) config('medicai.timeout', 30),
        );
    }

    /**
     * @param  array<string, mixed>  $clinicalContext
     * @param  array<string, mixed>  $options
     * @return array<string, mixed>
     */
    public function buildRequestPayload(string $operation, array $clinicalContext = [], array $options = []): array
    {
        return [
            'operation' => $operation,
            'base_url' => $this->baseUrl,
            'timeout' => $this->timeout ?? 30,
            'configured' => $this->isConfigured(),
            'timestamp' => now()->toIso8601String(),
            'context' => $clinicalContext,
            'options' => $options,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function healthCheck(): array
    {
        return $this->safeStub('health_check', fn (): array => [
            'available' => false,
            'configured' => $this->isConfigured(),
            'message' => $this->isConfigured()
                ? 'MedicAI placeholder is configured but outbound calls are intentionally disabled in Phase 1.'
                : 'MedicAI is not configured yet. Add MEDICAI_API_KEY and MEDICAI_BASE_URL to enable later integration.',
        ]);
    }

    /**
     * @param  array<string, mixed>  $clinicalContext
     * @param  array<string, mixed>  $options
     * @return array<string, mixed>
     */
    public function generateStructuredNote(array $clinicalContext = [], array $options = []): array
    {
        return $this->safeStub('structured_note_generation', fn (): array => [
            'payload' => $this->buildRequestPayload('structured_note_generation', $clinicalContext, $options),
            'status' => 'placeholder',
            'message' => 'Structured note generation is prepared but not yet connected to a live MedicAI endpoint.',
        ]);
    }

    /**
     * @param  array<string, mixed>  $clinicalContext
     * @param  array<string, mixed>  $options
     * @return array<string, mixed>
     */
    public function suggestSoapSections(array $clinicalContext = [], array $options = []): array
    {
        return $this->safeStub('soap_section_suggestion', fn (): array => [
            'payload' => $this->buildRequestPayload('soap_section_suggestion', $clinicalContext, $options),
            'status' => 'placeholder',
            'sections' => [],
            'message' => 'SOAP section suggestion is scaffolded for a later MedicAI integration.',
        ]);
    }

    /**
     * @param  array<string, mixed>  $clinicalContext
     * @param  array<string, mixed>  $options
     * @return array<string, mixed>
     */
    public function flagSafetyConcerns(array $clinicalContext = [], array $options = []): array
    {
        return $this->safeStub('safety_concern_flagging', fn (): array => [
            'payload' => $this->buildRequestPayload('safety_concern_flagging', $clinicalContext, $options),
            'status' => 'placeholder',
            'flags' => [],
            'message' => 'Safety concern flagging remains a non-clinical placeholder in Phase 4.',
        ]);
    }

    /**
     * @param  array<string, mixed>  $clinicalContext
     * @param  array<string, mixed>  $options
     * @return array<string, mixed>
     */
    public function suggestIcd10(array $clinicalContext = [], array $options = []): array
    {
        return $this->safeStub('icd10_suggestion', fn (): array => [
            'payload' => $this->buildRequestPayload('icd10_suggestion', $clinicalContext, $options),
            'status' => 'placeholder',
            'suggestions' => [],
            'message' => 'ICD-10 suggestion scaffolding is ready for later MedicAI integration.',
        ]);
    }

    private function isConfigured(): bool
    {
        return filled($this->apiKey) && filled($this->baseUrl);
    }

    /**
     * @param  callable(): array<string, mixed>  $callback
     * @return array<string, mixed>
     */
    private function safeStub(string $operation, callable $callback): array
    {
        try {
            return [
                'ok' => true,
                'operation' => $operation,
                'mode' => 'phase-4-placeholder',
                ...$callback(),
            ];
        } catch (Throwable $exception) {
            report($exception);

            return [
                'ok' => false,
                'operation' => $operation,
                'mode' => 'phase-4-placeholder',
                'message' => 'MedicAI placeholder call failed safely.',
            ];
        }
    }
}
