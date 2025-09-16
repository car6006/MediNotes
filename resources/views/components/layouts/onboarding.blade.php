<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}" class="dark">
    <head>
        @include('partials.head')
    </head>
    <body class="min-h-screen bg-slate-50 font-sans antialiased text-slate-900 dark:bg-neutral-950 dark:text-slate-100">
        <div class="flex min-h-svh flex-col">
            <header class="border-b border-slate-200/80 bg-white/80 backdrop-blur dark:border-slate-800 dark:bg-neutral-950/80">
                <div class="mx-auto flex w-full max-w-6xl items-center justify-between gap-4 px-6 py-5">
                    <a href="{{ route('home') }}" class="flex items-center gap-3" wire:navigate>
                        <span class="flex size-9 items-center justify-center rounded-md bg-slate-900 text-white dark:bg-white dark:text-slate-900">
                            <x-app-logo-icon class="size-5" />
                        </span>
                        <span class="text-base font-semibold tracking-tight">{{ config('app.name', 'MediNotes') }}</span>
                    </a>

                    <span class="text-xs uppercase tracking-wide text-slate-500 dark:text-slate-400">Guided onboarding</span>
                </div>
            </header>

            <main class="mx-auto flex w-full max-w-6xl flex-1 flex-col px-6 py-12">
                {{ $slot }}
            </main>
        </div>

        @fluxScripts
    </body>
</html>
