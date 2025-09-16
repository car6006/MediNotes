# MediNotes Implementation Backlog

The following numbered tickets break down the MediNotes build. Each item includes a semantic title, scope notes, suggested labels, story points (Fibonacci scale), and acceptance criteria.

1. **feat: scaffold onboarding authentication & wizard shell**
   * **Scope:** Install and configure Laravel Breeze with email verification, set up Livewire layout, and create the multi-step wizard container triggered post-registration.
   * **Labels:** `feature`, `frontend`, `backend`, `onboarding`
   * **Story Points:** 5
   * **Acceptance Criteria:**
     - Breeze auth views updated with MediNotes branding and email verification enforced.
     - Completing sign-up routes verified users into a Livewire-driven wizard shell with step navigation and persistence.
     - Wizard progress saved per user allowing resume after refresh.

2. **feat: compliance region & PHI step logic**
   * **Scope:** Implement wizard step for selecting compliance region (HIPAA, POPIA, GDPR) and toggling PHI usage with contextual guidance.
   * **Labels:** `feature`, `frontend`, `compliance`
   * **Story Points:** 3
   * **Acceptance Criteria:**
     - Compliance region options persisted on the user profile/team.
     - PHI toggle reveals BAA requirement messaging and cannot continue without acknowledgement.
     - Step validates selection before allowing progression.

3. **feat: BAA document upload and validation**
   * **Scope:** Allow teams to upload, store, and manage Business Associate Agreements; enforce validity dates when PHI toggle is enabled.
   * **Labels:** `feature`, `backend`, `storage`, `compliance`
   * **Story Points:** 5
   * **Acceptance Criteria:**
     - Teams can upload BAA PDFs to private storage with metadata (number, effective, expiry).
     - PHI-enabled accounts blocked if no active BAA; wizard displays actionable error.
     - Audit log records BAA upload and renewal actions.

4. **feat: practice setup step (create or join)**
   * **Scope:** Provide wizard step for creating a new practice or joining an existing one via invite/join code, including role assignment.
   * **Labels:** `feature`, `frontend`, `backend`, `practice`
   * **Story Points:** 5
   * **Acceptance Criteria:**
     - Users can create practices with name and address fields or join existing by invite token.
     - Team membership stored with role (owner, admin, member) and reflected on dashboard.
     - Step handles invalid invite tokens gracefully with inline feedback.

5. **feat: default engine, diarization, and redaction preferences**
   * **Scope:** Build wizard step for selecting transcription engine, diarization toggle, language auto-detect, and redaction default.
   * **Labels:** `feature`, `frontend`, `settings`
   * **Story Points:** 3
   * **Acceptance Criteria:**
     - Engine choices surfaced from config and persisted on user/practice defaults.
     - Diarization and redaction toggles persist and feed into future jobs.
     - Validation ensures at least one engine is selectable; unavailable engines hidden.

6. **feat: output format & specialty template preferences**
   * **Scope:** Combine wizard steps to capture preferred artifact formats (TXT, JSON, SRT, VTT, DOCX) and default specialty templates.
   * **Labels:** `feature`, `frontend`, `templates`
   * **Story Points:** 3
   * **Acceptance Criteria:**
     - Users can select multiple output formats with explanation of availability (DOCX optional).
     - Specialty template checklist persisted per user.
     - Wizard summary step confirms selections prior to dashboard redirect.

7. **feat: doctor dashboard layout & navigation**
   * **Scope:** Create dashboard view with welcome header, quick actions, recent encounters, analytics snapshot, and persistent sidebar navigation.
   * **Labels:** `feature`, `frontend`, `ui`
   * **Story Points:** 5
   * **Acceptance Criteria:**
     - Sidebar includes Dashboard, Encounters, Templates, Practice, Compliance, Settings.
     - Quick action buttons trigger navigation to encounter creation, upload modal, and recorder.
     - Recent encounters table and analytics placeholders render with sample data.

8. **feat: encounter quick action modal triggers**
   * **Scope:** Wire quick actions to modals/forms for recording voice, uploading audio, and uploading documents with consistent styling.
   * **Labels:** `feature`, `frontend`, `encounters`
   * **Story Points:** 5
   * **Acceptance Criteria:**
     - Record Voice modal includes start/pause/resume controls and waveform placeholder.
     - Upload Audio accepts drag-drop and file picker with validation on file types.
     - Upload Documents supports multiple file selection and indicates supported formats.

9. **feat: resumable chunked uploads (tier 1)**
   * **Scope:** Implement Livewire chunked uploads for files up to ~2 GB with progress tracking and retry on network loss.
   * **Labels:** `feature`, `backend`, `storage`
   * **Story Points:** 8
   * **Acceptance Criteria:**
     - Chunked upload progress bar updates in real time and resumes after transient failure.
     - Successful upload moves file to S3 (or configured disk) before finalization.
     - Upload manifest cleaned on completion or cancellation.

10. **feat: S3 multipart upload support (tier 2)**
    * **Scope:** Provide presigned multipart upload API for very large files with pause/resume and integrity validation of parts.
    * **Labels:** `feature`, `backend`, `storage`, `performance`
    * **Story Points:** 13
    * **Acceptance Criteria:**
      - Client receives upload id and part URLs, can pause/resume by reusing manifest.
      - Server validates ETags and assembles multipart object; mismatched parts flagged for re-upload.
      - Multipart uploads recoverable after browser refresh.

11. **feat: finalize encounter creation & dedup hashing**
    * **Scope:** Stream-hash uploaded files, enforce per-user dedup, and create transcription job entries with queued status.
    * **Labels:** `feature`, `backend`, `encounters`
    * **Story Points:** 8
    * **Acceptance Criteria:**
      - SHA-256 computed via stream without loading entire file into memory.
      - Duplicate uploads return existing job reference with notification to the user.
      - Finalization responds within 2 seconds after upload completion.

12. **feat: transcription job dispatch & queue workflow**
    * **Scope:** Create queue job for transcription processing, ensuring uniqueness, retries, and integration with engine driver abstraction.
    * **Labels:** `feature`, `backend`, `queue`
    * **Story Points:** 8
    * **Acceptance Criteria:**
      - Queue job transitions statuses (queued → processing → complete/failed) with progress updates.
      - Retries reuse stable external job ids; exponential backoff configured.
      - Failed jobs record error detail and emit events to timeline.

13. **feat: encounter detail processing timeline**
    * **Scope:** Build Encounter Detail page with header, file summary, status timeline, progress bar, and live event log.
    * **Labels:** `feature`, `frontend`, `encounters`
    * **Story Points:** 5
    * **Acceptance Criteria:**
      - Timeline shows stages (Queued, Processing, Diarizing/OCR, Outputs, Complete) with active state highlight.
      - Event log streams updates via Livewire polling or broadcast.
      - Download buttons remain disabled until artifacts exist.

14. **feat: OCR ingestion for document uploads**
    * **Scope:** Process uploaded document images/PDFs through OCR pipeline and merge text into encounter transcript package.
    * **Labels:** `feature`, `backend`, `ocr`
    * **Story Points:** 8
    * **Acceptance Criteria:**
      - OCR results stored alongside audio transcript segments with source metadata.
      - Errors isolated per document without failing entire encounter; surfaced in event log.
      - OCR respects PHI redaction settings.

15. **feat: medical AI summarization & coding**
    * **Scope:** Integrate medical LLM layer to generate clinical summary and propose ICD-10/SNOMED codes from combined transcript data.
    * **Labels:** `feature`, `backend`, `ai`, `billing`
    * **Story Points:** 13
    * **Acceptance Criteria:**
      - Summary text stored and displayed on encounter completion view.
      - Proposed codes include description, confidence, and editable fields.
      - Redaction rules applied before storing AI outputs when PHI flag is enabled.

16. **feat: encounter completion actions & downloads**
    * **Scope:** Display clinical summary, code approval checkboxes, template dropdown/preview, and download buttons for TXT, JSON, SRT, VTT, DOCX (if enabled).
    * **Labels:** `feature`, `frontend`, `encounters`
    * **Story Points:** 8
    * **Acceptance Criteria:**
      - Template preview auto-populates from transcript with editable fields.
      - Download buttons generate signed URLs with audit entries per click.
      - "Approve Codes & Send to Billing" triggers export workflow and status confirmation.

17. **feat: templates management page**
    * **Scope:** Provide templates index with preview, edit, set default, and add-new functionality, supporting template types (SOAP, Discharge, Referral, etc.).
    * **Labels:** `feature`, `frontend`, `templates`
    * **Story Points:** 5
    * **Acceptance Criteria:**
      - Templates list shows name, description, and type with action buttons.
      - Editing uses form with Livewire validation; changes versioned/audited.
      - Setting default updates user/practice preference used in encounters.

18. **feat: practice management workspace**
    * **Scope:** Build practice page showing profile details, linked doctors, admins, billing integration status, and BAA validity.
    * **Labels:** `feature`, `frontend`, `practice`
    * **Story Points:** 5
    * **Acceptance Criteria:**
      - Practice profile fields editable by owners/admins and read-only for members.
      - Linked users displayed with roles and invitation management.
      - Billing integrations status indicators reflect configured connectors.

19. **feat: compliance console**
    * **Scope:** Create compliance page summarizing region, PHI toggle, BAA upload/renew, data residency, and audit log export actions.
    * **Labels:** `feature`, `frontend`, `compliance`
    * **Story Points:** 5
    * **Acceptance Criteria:**
      - Page displays current compliance settings and allows toggling within policy constraints.
      - BAA renewal workflow accessible outside wizard with expiration warnings.
      - Audit log export triggers background job and delivers downloadable report.

20. **feat: user settings center**
    * **Scope:** Implement settings page for profile details, engine defaults, output format preferences, and notification toggles.
    * **Labels:** `feature`, `frontend`, `settings`
    * **Story Points:** 5
    * **Acceptance Criteria:**
      - Profile form updates name, specialty, and contact info with validation.
      - Engine and output preferences sync with encounter defaults.
      - Notification toggles persist and inform email/in-app alerts configuration.

21. **feat: analytics dashboard (doctor view)**
    * **Scope:** Deliver analytics view with charts for top ICD-10 codes, consultation types, average turnaround, and billing status split.
    * **Labels:** `feature`, `frontend`, `analytics`
    * **Story Points:** 8
    * **Acceptance Criteria:**
      - Charts render with Livewire-friendly visualization library using aggregated encounter data.
      - Analytics respect date filters and doctor/team scope.
      - Loading states and empty states handled gracefully.

22. **feat: billing export integration**
    * **Scope:** Implement export of approved codes to practice billing systems (Healthbridge, MedEDI, Vericlaim) and notify assigned billing agents.
    * **Labels:** `feature`, `backend`, `billing`, `integration`
    * **Story Points:** 13
    * **Acceptance Criteria:**
      - Billing connectors configurable per practice with credential validation.
      - Approved codes generate structured payloads and transmit via API/SFTP as configured.
      - Success/failure logged with retries on transient transport errors.

23. **chore: audit logging & compliance enforcement**
    * **Scope:** Capture audit events for uploads, downloads, retries, deletions, BAA actions, and ensure PHI redaction controls apply system-wide.
    * **Labels:** `chore`, `backend`, `compliance`, `security`
    * **Story Points:** 8
    * **Acceptance Criteria:**
      - Audit table populated for each sensitive action with actor, timestamp, and metadata.
      - PHI-flagged jobs mask sensitive text in logs and event streams.
      - Compliance reports exportable per time range for regulators.

24. **chore: observability & admin queue monitoring**
    * **Scope:** Provide admin-only dashboard summarizing queue health, job throughput, failures, and link to Horizon (if Redis) or custom metrics.
    * **Labels:** `chore`, `backend`, `observability`
    * **Story Points:** 5
    * **Acceptance Criteria:**
      - Admin dashboard displays queue depth, average processing time, and failure counts.
      - Admins can requeue or cancel stuck jobs with confirmation prompts.
      - Access restricted to admin role with audit entries for actions.

25. **chore: automated testing & CI scaffolding**
    * **Scope:** Establish Pest/PHPUnit suites covering core flows, configure GitHub Actions (or alternative) for linting, tests, and asset build, and document runbook.
    * **Labels:** `chore`, `testing`, `ci-cd`
    * **Story Points:** 5
    * **Acceptance Criteria:**
      - Unit and feature tests cover upload finalization, dedup, permissions, artifact downloads, and billing export stubs.
      - CI pipeline runs linting and tests on pull requests with status badges.
      - README updated with testing commands and CI overview.
