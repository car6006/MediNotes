<?php

use App\Support\Onboarding;
use Livewire\Attributes\Layout;
use Livewire\Attributes\Title;
use Livewire\Volt\Component;

new #[Layout('components.layouts.onboarding'), Title('Complete MediNotes onboarding')] class extends Component {
    /**
     * @var array<int, array<string, string>>
     */
    public array $steps = [];

    public int $currentStep = 1;

    /**
     * @var array<int>
     */
    public array $completedSteps = [];

    public bool $emailJustVerified = false;

    public function mount(): void
    {
        $this->steps = Onboarding::steps();
        $this->emailJustVerified = request()->boolean('verified');

        $user = auth()->user();
        $user->initializeOnboardingState();
        $user->refresh();

        $state = $user->onboarding_state ?? [];

        $this->currentStep = (int) ($state['current_step'] ?? $user->onboarding_step ?? 1);
        $this->completedSteps = array_values(array_unique(array_map('intval', $state['completed'] ?? [])));
        sort($this->completedSteps);

        $this->persistProgress();
    }

    public function goToStep(int $step): void
    {
        if (! $this->isValidStep($step)) {
            return;
        }

        $this->currentStep = $step;
        $this->persistProgress();
    }

    public function nextStep(): void
    {
        if ($this->currentStep >= count($this->steps)) {
            return;
        }

        $this->markStepCompleted($this->currentStep);
        $this->currentStep++;
        $this->persistProgress();
    }

    public function previousStep(): void
    {
        if ($this->currentStep <= 1) {
            return;
        }

        $this->currentStep--;
        $this->persistProgress();
    }

    public function complete(): void
    {
        $totalSteps = count($this->steps);

        $this->markStepCompleted($this->currentStep);
        $this->currentStep = $totalSteps;
        $this->completedSteps = range(1, $totalSteps);

        $user = auth()->user();
        $user->forceFill([
            'onboarding_step' => $this->currentStep,
            'onboarding_state' => [
                'current_step' => $this->currentStep,
                'completed' => $this->completedSteps,
                'total' => Onboarding::totalSteps(),
            ],
            'onboarded_at' => now(),
        ])->save();

        $this->redirect(route('dashboard', absolute: false), navigate: true);
    }

    protected function markStepCompleted(int $step): void
    {
        if (! in_array($step, $this->completedSteps, true)) {
            $this->completedSteps[] = $step;
            sort($this->completedSteps);
        }
    }

    protected function persistProgress(): void
    {
        $user = auth()->user();

        $user->forceFill([
            'onboarding_step' => $this->currentStep,
            'onboarding_state' => [
                'current_step' => $this->currentStep,
                'completed' => $this->completedSteps,
                'total' => Onboarding::totalSteps(),
            ],
        ])->save();
    }

    protected function isValidStep(int $step): bool
    {
        return $step >= 1 && $step <= count($this->steps);
    }
}; ?>

@php
    $totalSteps = count($steps);
    $activeStep = $steps[$currentStep - 1] ?? null;
    $progress = $totalSteps > 0 ? intval(($currentStep / $totalSteps) * 100) : 0;

    $placeholderCopy = static fn (array $step): string => match ($step['key']) {
        'compliance-region' => 'Capture the regulatory region so MediNotes can apply HIPAA, POPIA, or GDPR storage rules. The upcoming step will surface these options with contextual guidance.',
        'phi-toggle' => 'Decide whether this account will handle PHI. When implemented, enabling PHI will prompt for a Business Associate Agreement upload before the doctor can continue.',
        'practice-setup' => 'Set up the practice space by creating a new organisation or joining an existing invite. Role assignments and invite handling will be wired in the following tickets.',
        'processing-defaults' => 'Choose the default transcription engine, diarisation, redaction, and language handling options. Future tasks will persist these defaults to every new encounter.',
        'outputs' => 'Pick the transcript formats that should be generated automatically (TXT, JSON, SRT, VTT, DOCX). Later work will store these preferences for downstream processing.',
        'templates' => 'Select specialty templates such as SOAP, Discharge, or Referral notes. Template management and preview will land in subsequent tickets.',
        default => 'Configure the remaining onboarding preferences.',
    };
@endphp

<div class="space-y-10">
    <header class="space-y-4">
        <div>
            <p class="text-sm font-semibold uppercase tracking-wide text-slate-500">Onboarding</p>
            <h1 class="text-3xl font-semibold text-slate-900 dark:text-white">Complete your MediNotes setup</h1>
            <p class="mt-2 text-sm text-slate-600 dark:text-slate-300">
                Step {{ $currentStep }} of {{ $totalSteps }} · Progress {{ $progress }}%
            </p>
        </div>

        <div class="h-2 w-full overflow-hidden rounded-full bg-slate-200 dark:bg-slate-700">
            <div class="h-full bg-sky-500 transition-all duration-300" style="width: {{ $progress }}%;"></div>
        </div>

        @if ($emailJustVerified)
            <flux:alert variant="success">
                {{ __('Thanks for verifying your email address. Let’s finish configuring MediNotes before you jump into encounters.') }}
            </flux:alert>
        @endif
    </header>

    <div class="grid gap-10 lg:grid-cols-[280px_1fr]">
        <aside class="space-y-4">
            <ol class="space-y-2">
                @foreach ($steps as $index => $step)
                    @php
                        $stepNumber = $index + 1;
                        $isActive = $currentStep === $stepNumber;
                        $isComplete = in_array($stepNumber, $completedSteps, true);
                    @endphp
                    <li>
                        <button
                            type="button"
                            wire:click="goToStep({{ $stepNumber }})"
                            class="flex w-full items-center justify-between gap-3 rounded-lg border px-4 py-3 text-left transition hover:border-sky-400 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-500 @if($isActive) border-sky-500 bg-sky-50 text-sky-900 dark:border-sky-400 dark:bg-sky-950 dark:text-sky-100 @elseif($isComplete) border-emerald-400 bg-emerald-50 text-emerald-900 dark:border-emerald-400 dark:bg-emerald-950 dark:text-emerald-100 @else border-slate-200 dark:border-slate-700 text-slate-700 dark:text-slate-200 @endif"
                            @if($isActive) aria-current="step" @endif
                        >
                            <span class="flex items-center gap-3">
                                <span class="flex size-7 items-center justify-center rounded-full text-sm font-semibold @if($isComplete) bg-emerald-500 text-white @elseif($isActive) bg-sky-500 text-white @else bg-slate-200 text-slate-700 dark:bg-slate-700 dark:text-slate-200 @endif">
                                    {{ $stepNumber }}
                                </span>
                                <span class="flex flex-col">
                                    <span class="text-sm font-medium">{{ $step['title'] }}</span>
                                    <span class="text-xs text-slate-500 dark:text-slate-400">{{ $step['description'] }}</span>
                                </span>
                            </span>
                            @if ($isComplete && ! $isActive)
                                <span class="text-xs font-semibold uppercase tracking-wide text-emerald-600 dark:text-emerald-400">Done</span>
                            @endif
                        </button>
                    </li>
                @endforeach
            </ol>
        </aside>

        <section class="space-y-6">
            @if ($activeStep)
                <div class="space-y-4 rounded-2xl border border-slate-200 bg-white p-8 shadow-sm dark:border-slate-700 dark:bg-slate-900">
                    <header class="space-y-2">
                        <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">{{ __('Current step') }}</p>
                        <h2 class="text-2xl font-semibold text-slate-900 dark:text-white">{{ $activeStep['title'] }}</h2>
                        <p class="text-sm text-slate-600 dark:text-slate-300">{{ $activeStep['description'] }}</p>
                    </header>

                    <div class="rounded-xl border border-dashed border-slate-300 bg-slate-50 p-6 text-sm text-slate-600 dark:border-slate-600 dark:bg-slate-800/60 dark:text-slate-200">
                        {{ $placeholderCopy($activeStep) }}
                        <br><br>
                        {{ __('This shell keeps your place. Upcoming tickets will replace it with the real form controls and data binding for each configuration step.') }}
                    </div>
                </div>
            @endif

            <div class="flex flex-wrap items-center justify-between gap-3">
                <flux:button
                    type="button"
                    variant="ghost"
                    wire:click="previousStep"
                    :disabled="$currentStep === 1"
                >
                    {{ __('Back') }}
                </flux:button>

                <div class="flex items-center gap-3">
                    @if ($currentStep < $totalSteps)
                        <flux:button
                            type="button"
                            variant="outline"
                            wire:click="nextStep"
                        >
                            {{ __('Save & continue') }}
                        </flux:button>
                    @else
                        <flux:button
                            type="button"
                            variant="primary"
                            wire:click="complete"
                        >
                            {{ __('Finish setup') }}
                        </flux:button>
                    @endif
                </div>
            </div>
        </section>
    </div>
</div>
