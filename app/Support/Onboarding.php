<?php

namespace App\Support;

class Onboarding
{
    /**
     * Retrieve the ordered onboarding steps.
     *
     * @return array<int, array<string, string>>
     */
    public static function steps(): array
    {
        return [
            [
                'key' => 'compliance-region',
                'title' => 'Compliance region',
                'description' => 'Select where MediNotes should enforce jurisdictional rules.',
            ],
            [
                'key' => 'phi-toggle',
                'title' => 'Protected health information',
                'description' => 'Declare whether the practice will store PHI and handle BAA obligations.',
            ],
            [
                'key' => 'practice-setup',
                'title' => 'Practice workspace',
                'description' => 'Create or join the practice that will use MediNotes.',
            ],
            [
                'key' => 'processing-defaults',
                'title' => 'Processing defaults',
                'description' => 'Choose engines, diarization, and redaction defaults for new encounters.',
            ],
            [
                'key' => 'outputs',
                'title' => 'Output formats',
                'description' => 'Confirm which transcript artifacts should be generated automatically.',
            ],
            [
                'key' => 'templates',
                'title' => 'Specialty templates',
                'description' => 'Select the clinical note templates that best match the practice.',
            ],
        ];
    }

    /**
     * Get the total number of onboarding steps.
     */
    public static function totalSteps(): int
    {
        return count(self::steps());
    }
}
