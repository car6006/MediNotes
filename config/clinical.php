<?php

return [
    'privacy_notice_version' => env('CLINICAL_PRIVACY_NOTICE_VERSION', '2026-03'),

    'api_access_permission' => env('CLINICAL_API_ACCESS_PERMISSION', 'clinical-api.access'),

    'dictation' => [
        'require_recording_consent' => (bool) env('CLINICAL_REQUIRE_RECORDING_CONSENT', true),
        'require_ai_consent' => (bool) env('CLINICAL_REQUIRE_AI_CONSENT', true),
    ],
];
