<?php

use Illuminate\Support\Facades\Route;
use Livewire\Volt\Volt;

Route::get('/', function () {
    return view('welcome');
})->name('home');

Route::view('dashboard', 'dashboard')
    ->middleware(['auth', 'verified', 'onboarding.complete'])
    ->name('dashboard');

Volt::route('onboarding', 'onboarding.wizard')
    ->middleware(['auth', 'verified', 'onboarding.incomplete'])
    ->name('onboarding.wizard');

Route::middleware(['auth', 'verified', 'onboarding.complete'])->group(function () {
    Route::redirect('settings', 'settings/profile');

    Volt::route('settings/profile', 'settings.profile')->name('settings.profile');
    Volt::route('settings/password', 'settings.password')->name('settings.password');
    Volt::route('settings/appearance', 'settings.appearance')->name('settings.appearance');
});

require __DIR__.'/auth.php';
