# MediNotes Flutter

Flutter web + mobile scaffold for an offline-first clinical workflow.

The app now includes secure sign-in, encrypted offline cache storage, secure bearer-token storage, and visit-level consent capture for dictation / offline transcription.

## Core workflow

- sign in with the Laravel Sanctum API
- lookup returning patients
- create new patient records
- review visit history and medical history
- dictate short notes on-device
- record longer consult audio and transcribe with offline Whisper on native builds
- apply clinical templates
- queue local changes and replay them to Laravel when the API is reachable
- wipe local encrypted cache on logout

## Run against the Laravel API

Start the Laravel server from the repository root, then run Flutter with the API base URL defined:

```bash
flutter run \
	--dart-define=MEDINOTES_API_BASE_URL=http://127.0.0.1:8000/api/v1
```

For web:

```bash
flutter run -d chrome \
	--dart-define=MEDINOTES_API_BASE_URL=http://127.0.0.1:8000/api/v1
```

## Offline transcription notes

- Short dictation uses the platform speech recognizer with on-device mode requested.
- Longer consult transcription is wired through `whisper_ggml` on native builds.
- Web builds keep the same workflow shell but do not enable long-form Whisper yet.
- The workflow requires privacy acknowledgement, recording consent, and AI transcription consent before dictated content can be saved.

## Security notes

- API tokens are issued by Laravel Sanctum.
- Tokens are stored with `flutter_secure_storage`.
- Local clinical cache is encrypted before it is written to preferences.
- Signing out clears the stored token and encrypted cache.
- The app restores the previous session from secure storage when possible.

## Next hardening steps

- move the encrypted cache to a dedicated local encrypted database when note volume grows
- add token refresh and forced re-authentication policy options
- add audit log review/export surfaces for administrators
- add structured diagnosis, medication, and observation coding
