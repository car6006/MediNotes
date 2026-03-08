# MediNotes platform scaffold

## What was scaffolded

- Laravel medical workflow API under `/api/v1`
- Patient, visit, template, and dictation domain models
- Offline-first Flutter client in `medinotes_flutter/`
- Short on-device dictation flow using platform speech recognition
- Long-form offline transcription bridge using `whisper_ggml`
- Local queueing and replay-based sync for patient, visit, template, and dictation changes
- Sanctum API authentication for mobile/web clients
- Audit logging for authentication and clinical data access events
- Visit-level POPIA-style consent metadata for recording and AI transcription
- Encrypted Flutter cache at rest plus secure token storage

## Linked clinical process

1. **Doctor opens patient search**
   - Search cached patients locally
   - Refresh against Laravel API when online
2. **New patient**
   - Create patient record with demographics, allergies, medications, and medical history
3. **Returning patient**
   - Load prior visits and existing medical history
4. **During consult**
   - Short dictation: on-device speech recognition
   - Longer consult capture: record audio and transcribe with offline Whisper on native builds
5. **Clinical note creation**
   - Choose a note template
   - Fill subjective, objective, assessment, plan, transcript, and patient update
6. **Patient update and sync**
   - Save locally first
   - Queue replay pushes changes to Laravel API when available

## Laravel endpoints

- `POST /api/v1/auth/login`
- `GET /api/v1/auth/me`
- `POST /api/v1/auth/logout`
- `GET /api/v1/bootstrap`
- `GET /api/v1/patients?search=`
- `POST /api/v1/patients`
- `PUT /api/v1/patients/{id}`
- `GET /api/v1/patients/{id}`
- `GET /api/v1/visits`
- `POST /api/v1/visits`
- `PUT /api/v1/visits/{id}`
- `GET /api/v1/visits/{id}`
- `GET /api/v1/note-templates`
- `POST /api/v1/note-templates`
- `PUT /api/v1/note-templates/{id}`
- `POST /api/v1/visits/{visit}/dictations`

All clinical endpoints other than login now require a Sanctum bearer token and return no-store response headers.

## Security and POPIA-aligned controls

- API access is limited to configured clinical roles such as `admin` and `clinician`.
- Audit log rows are created for login success/failure, bootstrap access, patient search/view, visit access, dictation capture, and template access.
- Visit payloads now store:
   - privacy notice acknowledgement timestamp
   - recording consent timestamp and capture method
   - AI transcription consent timestamp
   - optional consent notes
- Dictation storage is rejected by the API unless the visit already carries the required consent metadata.
- Flutter stores session tokens in secure device storage and encrypts the local clinical cache before writing to shared preferences.
- Signing out wipes the encrypted local cache and the stored bearer token.

## Flutter runtime notes

- Flutter web and mobile share the same data workflow.
- Offline Whisper is wired for native builds through `whisper_ggml`.
- Web builds still handle patient lookup, notes, templates, and sync, but long-form Whisper stays disabled until a web-safe WASM worker path is chosen.
- The app now opens on a secure sign-in screen and restores the previous session from secure storage when available.
- The visit workflow requires privacy acknowledgement plus recording / transcription consent before dictation can start.
- The API base URL is configurable with:

  - `--dart-define=MEDINOTES_API_BASE_URL=http://127.0.0.1:8000/api/v1`

## Suggested next steps

- Replace JSON preference storage with a larger encrypted local database when data volume grows
- Add token refresh or short-session re-authentication policy for long-running offline shifts
- Add patient-facing consent document generation and signed attachment storage
- Add structured coding for diagnoses, medications, and observations
