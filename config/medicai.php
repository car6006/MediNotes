<?php

return [
    'api_key' => env('MEDICAI_API_KEY'),
    'base_url' => env('MEDICAI_BASE_URL', 'https://api.medicai.local'),
    'timeout' => (int) env('MEDICAI_TIMEOUT', 30),
    'enabled' => filled(env('MEDICAI_API_KEY')),
    'features' => [
        'health_check' => true,
        'structured_note_generation' => true,
        'icd10_suggestions' => true,
    ],
];
