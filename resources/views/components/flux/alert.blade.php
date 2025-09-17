@props([
    'variant' => 'info',
    'heading' => null,
])

@php
    $variant = strtolower($variant ?? 'info');

    $aliases = [
        'primary' => 'info',
        'secondary' => 'muted',
        'neutral' => 'muted',
        'error' => 'danger',
    ];

    $variant = $aliases[$variant] ?? $variant;

    $styles = [
        'info' => [
            'wrapper' => 'border-sky-200 bg-sky-50 text-sky-900 dark:border-sky-500/40 dark:bg-sky-500/10 dark:text-sky-100',
            'indicator' => 'bg-sky-500 dark:bg-sky-400',
        ],
        'success' => [
            'wrapper' => 'border-emerald-200 bg-emerald-50 text-emerald-900 dark:border-emerald-500/40 dark:bg-emerald-500/10 dark:text-emerald-100',
            'indicator' => 'bg-emerald-500 dark:bg-emerald-400',
        ],
        'warning' => [
            'wrapper' => 'border-amber-200 bg-amber-50 text-amber-900 dark:border-amber-500/40 dark:bg-amber-500/10 dark:text-amber-100',
            'indicator' => 'bg-amber-500 dark:bg-amber-400',
        ],
        'danger' => [
            'wrapper' => 'border-rose-200 bg-rose-50 text-rose-900 dark:border-rose-500/40 dark:bg-rose-500/10 dark:text-rose-100',
            'indicator' => 'bg-rose-500 dark:bg-rose-400',
        ],
        'muted' => [
            'wrapper' => 'border-slate-200 bg-white text-slate-800 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100',
            'indicator' => 'bg-slate-400 dark:bg-slate-500',
        ],
    ];

    $style = $styles[$variant] ?? $styles['info'];
@endphp

<div {{ $attributes->class([
    'flex gap-3 rounded-2xl border px-4 py-3 text-sm leading-6 shadow-sm dark:shadow-none',
    $style['wrapper'],
]) }}>
    <span class="mt-1.5 inline-flex size-2.5 flex-none rounded-full {{ $style['indicator'] }}"></span>

    <div class="flex flex-1 flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div class="space-y-1.5 text-sm leading-6">
            @if ($heading)
                <p class="font-semibold">{{ $heading }}</p>
            @endif

            <div class="text-sm leading-6">
                {{ $slot }}
            </div>
        </div>

        @isset($actions)
            <div class="flex shrink-0 items-center gap-2 text-sm font-medium sm:ps-4">
                {{ $actions }}
            </div>
        @endisset
    </div>
</div>
