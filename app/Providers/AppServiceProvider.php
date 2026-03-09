<?php

namespace App\Providers;

use App\Models\AudioFile;
use App\Models\ClinicalNote;
use App\Models\Encounter;
use App\Models\EncounterTemplate;
use App\Models\NoteTemplate;
use App\Models\Appointment;
use App\Models\ConsentTemplate;
use App\Models\OnboardingForm;
use App\Models\OnboardingResponse;
use App\Models\Patient;
use App\Models\PatientConsent;
use App\Models\Transcript;
use App\Models\Visit;
use App\Policies\AudioFilePolicy;
use App\Policies\AppointmentPolicy;
use App\Policies\ClinicalNotePolicy;
use App\Policies\ConsentTemplatePolicy;
use App\Policies\EncounterPolicy;
use App\Policies\EncounterTemplatePolicy;
use App\Policies\NoteTemplatePolicy;
use App\Policies\OnboardingFormPolicy;
use App\Policies\OnboardingResponsePolicy;
use App\Policies\PatientPolicy;
use App\Policies\PatientConsentPolicy;
use App\Policies\TranscriptPolicy;
use App\Policies\VisitPolicy;
use App\Services\MedicAIService;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\Date;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;
use Illuminate\Validation\Rules\Password;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->singleton(MedicAIService::class, static fn (): MedicAIService => MedicAIService::fromConfig());
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        $this->configureDefaults();
        $this->registerAuthorizationFoundation();
    }

    /**
     * Configure default behaviors for production-ready applications.
     */
    protected function configureDefaults(): void
    {
        Date::use(CarbonImmutable::class);

        DB::prohibitDestructiveCommands(
            app()->isProduction(),
        );

        Password::defaults(fn (): ?Password => app()->isProduction()
            ? Password::min(12)
                ->mixedCase()
                ->letters()
                ->numbers()
                ->symbols()
                ->uncompromised()
            : null,
        );
    }

    protected function registerAuthorizationFoundation(): void
    {
        Gate::policy(Appointment::class, AppointmentPolicy::class);
        Gate::policy(OnboardingForm::class, OnboardingFormPolicy::class);
        Gate::policy(OnboardingResponse::class, OnboardingResponsePolicy::class);
        Gate::policy(ConsentTemplate::class, ConsentTemplatePolicy::class);
        Gate::policy(PatientConsent::class, PatientConsentPolicy::class);
        Gate::policy(Patient::class, PatientPolicy::class);
        Gate::policy(Visit::class, VisitPolicy::class);
        Gate::policy(Encounter::class, EncounterPolicy::class);
        Gate::policy(AudioFile::class, AudioFilePolicy::class);
        Gate::policy(Transcript::class, TranscriptPolicy::class);
        Gate::policy(ClinicalNote::class, ClinicalNotePolicy::class);
        Gate::policy(NoteTemplate::class, NoteTemplatePolicy::class);
        Gate::policy(EncounterTemplate::class, EncounterTemplatePolicy::class);

        foreach (config('rbac.permissions', []) as $permission) {
            $slug = $permission['slug'] ?? null;

            if (! is_string($slug) || $slug === '') {
                continue;
            }

            Gate::define($slug, static fn ($user): bool => $user->hasPermissionTo($slug));
        }
    }
}
