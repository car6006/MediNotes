<?php

return [
    'default_role' => env('RBAC_DEFAULT_ROLE', 'clinician'),

    'permissions' => [
        [
            'name' => 'Access clinical API',
            'slug' => 'clinical-api.access',
            'group' => 'platform',
            'description' => 'Authenticate and use the clinical API surface.',
        ],
        [
            'name' => 'Read patients',
            'slug' => 'patients.read',
            'group' => 'patients',
            'description' => 'View patient demographics and clinical history.',
        ],
        [
            'name' => 'Write patients',
            'slug' => 'patients.write',
            'group' => 'patients',
            'description' => 'Create and update patient records.',
        ],
        [
            'name' => 'Read visits',
            'slug' => 'visits.read',
            'group' => 'visits',
            'description' => 'View visit history and encounter records.',
        ],
        [
            'name' => 'Write visits',
            'slug' => 'visits.write',
            'group' => 'visits',
            'description' => 'Create and update clinical visits.',
        ],
        [
            'name' => 'Write dictations',
            'slug' => 'dictations.write',
            'group' => 'dictation',
            'description' => 'Store offline dictation and transcription payloads.',
        ],
        [
            'name' => 'Read templates',
            'slug' => 'templates.read',
            'group' => 'templates',
            'description' => 'View clinical note templates.',
        ],
        [
            'name' => 'Write templates',
            'slug' => 'templates.write',
            'group' => 'templates',
            'description' => 'Create and update clinical note templates.',
        ],
        [
            'name' => 'Read appointments',
            'slug' => 'appointments.read',
            'group' => 'appointments',
            'description' => 'View booked, active, and historical appointments.',
        ],
        [
            'name' => 'Write appointments',
            'slug' => 'appointments.write',
            'group' => 'appointments',
            'description' => 'Create and update appointment bookings and status transitions.',
        ],
        [
            'name' => 'Read onboarding',
            'slug' => 'onboarding.read',
            'group' => 'onboarding',
            'description' => 'View onboarding forms and submitted onboarding responses.',
        ],
        [
            'name' => 'Write onboarding',
            'slug' => 'onboarding.write',
            'group' => 'onboarding',
            'description' => 'Submit patient onboarding responses.',
        ],
        [
            'name' => 'Read consents',
            'slug' => 'consents.read',
            'group' => 'consents',
            'description' => 'View consent templates and patient consent history.',
        ],
        [
            'name' => 'Write consents',
            'slug' => 'consents.write',
            'group' => 'consents',
            'description' => 'Capture patient consent acceptance records.',
        ],
        [
            'name' => 'Read clinics',
            'slug' => 'clinics.read',
            'group' => 'clinics',
            'description' => 'View clinic profile records.',
        ],
        [
            'name' => 'Read providers',
            'slug' => 'providers.read',
            'group' => 'providers',
            'description' => 'View provider profile records.',
        ],
        [
            'name' => 'Use MedicAI',
            'slug' => 'medicai.use',
            'group' => 'medicai',
            'description' => 'Use MedicAI integration endpoints when enabled.',
        ],
    ],

    'roles' => [
        'admin' => [
            'name' => 'Administrator',
            'description' => 'Full platform administration across clinics and security settings.',
            'is_system' => true,
            'permissions' => '*',
        ],
        'clinician' => [
            'name' => 'Clinician',
            'description' => 'Clinical user with access to patient, visit, dictation, and template workflows.',
            'is_system' => true,
            'permissions' => [
                'clinical-api.access',
                'patients.read',
                'patients.write',
                'visits.read',
                'visits.write',
                'dictations.write',
                'templates.read',
                'templates.write',
                'appointments.read',
                'appointments.write',
                'onboarding.read',
                'onboarding.write',
                'consents.read',
                'consents.write',
                'clinics.read',
                'providers.read',
            ],
        ],
        'viewer' => [
            'name' => 'Viewer',
            'description' => 'Limited non-clinical user with no clinical API access by default.',
            'is_system' => true,
            'permissions' => [],
        ],
    ],
];
