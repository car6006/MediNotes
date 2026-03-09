<?php

use Tests\TestCase;
use App\Enums\EncounterStatus;
use App\Models\Encounter;
use App\Support\EncounterStateMachine;
use Illuminate\Validation\ValidationException;

uses(TestCase::class);

it('progresses encounter state forward and stamps lifecycle timestamps', function () {
    $encounter = Encounter::make([
        'status' => EncounterStatus::CREATED->value,
    ]);

    $attributes = (new EncounterStateMachine())->progress($encounter, EncounterStatus::DRAFT_NOTE_READY);

    expect($attributes['status'])->toBe(EncounterStatus::DRAFT_NOTE_READY->value)
        ->and($attributes)->toHaveKeys([
            'status_changed_at',
            'started_at',
            'in_progress_at',
            'dictation_captured_at',
            'transcription_pending_at',
            'draft_note_ready_at',
        ]);
});

it('rejects invalid encounter transitions', function () {
    $encounter = Encounter::make([
        'status' => EncounterStatus::CREATED->value,
    ]);

    expect(fn () => (new EncounterStateMachine())->transition($encounter, EncounterStatus::COMPLETED))
        ->toThrow(ValidationException::class);
});
