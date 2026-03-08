import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';

import '../features/patients/presentation/screens/patient_list_screen.dart';
import 'controller.dart';
import 'models.dart';
import 'offline_transcriber.dart';
import 'recording_path.dart';
import 'repository.dart';
import 'router.dart';
import 'session_controller.dart';

const _uuid = Uuid();

class ClinicShell extends ConsumerStatefulWidget {
  const ClinicShell({super.key});

  @override
  ConsumerState<ClinicShell> createState() => _ClinicShellState();
}

class _ClinicShellState extends ConsumerState<ClinicShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(clinicControllerProvider);
    final session = ref.watch(sessionControllerProvider).valueOrNull;

    return asyncState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('MediNotes')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Unable to load the clinical workspace.',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(clinicControllerProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (state) {
        final controller = ref.read(clinicControllerProvider.notifier);
        final pages = [
          DashboardPage(state: state, session: session),
          PatientsPage(state: state, controller: controller),
          VisitWorkflowPage(
            state: state,
            controller: controller,
            session: session,
          ),
          TemplatesPage(state: state, controller: controller),
          SyncPage(state: state, controller: controller),
        ];

        final destinations = const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Patients',
          ),
          NavigationDestination(icon: Icon(Icons.mic_none), label: 'Workflow'),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            label: 'Templates',
          ),
          NavigationDestination(icon: Icon(Icons.sync_outlined), label: 'Sync'),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final useRail = constraints.maxWidth >= 1100;

            if (useRail) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text(
                    'MediNotes · Web + Mobile Clinic Workspace',
                  ),
                  actions: _buildAppBarActions(context, state, session),
                ),
                body: Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (index) {
                        setState(() => _selectedIndex = index);
                      },
                      labelType: NavigationRailLabelType.all,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          label: Text('Dashboard'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.people_outline),
                          label: Text('Patients'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.mic_none),
                          label: Text('Workflow'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.description_outlined),
                          label: Text('Templates'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.sync_outlined),
                          label: Text('Sync'),
                        ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: pages[_selectedIndex],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Scaffold(
              appBar: AppBar(
                title: const Text('MediNotes'),
                actions: _buildAppBarActions(context, state, session),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: pages[_selectedIndex],
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _selectedIndex,
                destinations: destinations,
                onDestinationSelected: (index) {
                  setState(() => _selectedIndex = index);
                },
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildAppBarActions(
    BuildContext context,
    ClinicState state,
    AuthSession? session,
  ) {
    final compact = MediaQuery.of(context).size.width < 900;

    return [
      if (state.syncMessage?.isNotEmpty ?? false)
        compact
            ? Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Tooltip(
                  message: state.syncMessage!,
                  child: Icon(
                    Icons.shield_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: Text(
                      state.syncMessage!,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
      if (session != null)
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Center(
            child: compact
                ? Tooltip(
                    message: '${session.user.name} · ${session.user.role}',
                    child: CircleAvatar(
                      radius: 16,
                      child: Text(
                        session.user.name.trim().isEmpty
                            ? '?'
                            : session.user.name
                                  .trim()
                                  .substring(0, 1)
                                  .toUpperCase(),
                      ),
                    ),
                  )
                : Chip(
                    avatar: const Icon(Icons.verified_user_outlined, size: 18),
                    label: Text('${session.user.name} · ${session.user.role}'),
                  ),
          ),
        ),
      if (session != null)
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconButton(
            tooltip: 'Sign out and wipe local cache',
            onPressed: () async {
              await ref.read(sessionControllerProvider.notifier).logout();

              if (!context.mounted) {
                return;
              }

              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRouter.login,
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ),
    ];
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.state, this.session});

  final ClinicState state;
  final AuthSession? session;

  @override
  Widget build(BuildContext context) {
    final recentVisits = [...state.visits]
      ..sort(
        (a, b) => (b.startedAt ?? DateTime(1970)).compareTo(
          a.startedAt ?? DateTime(1970),
        ),
      );

    final recentPatients = [...state.patients]
      ..sort(
        (a, b) => (b.lastVisitAt ?? DateTime(1970)).compareTo(
          a.lastVisitAt ?? DateTime(1970),
        ),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Clinical command center',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Start with patient lookup, dictate the encounter, capture longer consult audio with offline Whisper on device, and keep local changes queued until the backend is reachable.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (session != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Signed in as ${session!.user.name}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '${session!.user.email} · ${session!.user.role}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Privacy notice ${session!.security.privacyNoticeVersion ?? 'current'} · '
                  'Encrypted cache ${session!.security.encryptedLocalCacheRequired ? 'required' : 'optional'} · '
                  'Consent for recording ${session!.security.recordingRequiresConsent ? 'required' : 'not required'}',
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _MetricCard(
              label: 'Patients',
              value: state.patients.length.toString(),
              icon: Icons.people_outline,
            ),
            _MetricCard(
              label: 'Visits',
              value: state.visits.length.toString(),
              icon: Icons.event_note_outlined,
            ),
            _MetricCard(
              label: 'Templates',
              value: state.templates.length.toString(),
              icon: Icons.description_outlined,
            ),
            _MetricCard(
              label: 'Pending sync',
              value: state.queue.length.toString(),
              icon: Icons.cloud_upload_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SectionCard(
          title: 'Linked workflow',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _WorkflowStep(
                step: '1',
                title: 'Lookup or register patient',
                body:
                    'Search by name or MRN. If the patient is new, create the record and capture baseline medical history, allergies, and medications.',
              ),
              _WorkflowStep(
                step: '2',
                title: 'Open encounter workflow',
                body:
                    'Select a note template, review the visit timeline, and choose between short live dictation or longer offline Whisper transcription.',
              ),
              _WorkflowStep(
                step: '3',
                title: 'Finalize notes and update plan',
                body:
                    'Save the structured note, patient update, and transcript. Changes sync automatically when the Laravel API is reachable again.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _SectionCard(
          title: 'Recent patients',
          child: Column(
            children: recentPatients.take(5).map((patient) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(patient.fullName),
                subtitle: Text(patient.medicalRecordNumber),
                trailing: Text(_formatDateTime(patient.lastVisitAt)),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        _SectionCard(
          title: 'Recent visits',
          child: Column(
            children: recentVisits.take(5).map((visit) {
              final patient = _patientById(state.patients, visit.patientId);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.medical_services_outlined),
                ),
                title: Text(visit.chiefComplaint ?? 'Clinical note draft'),
                subtitle: Text(patient?.fullName ?? visit.patientId),
                trailing: Text(_formatDateTime(visit.startedAt)),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class PatientsPage extends StatelessWidget {
  const PatientsPage({
    super.key,
    required this.state,
    required this.controller,
  });

  final ClinicState state;
  final ClinicController controller;

  @override
  Widget build(BuildContext context) {
    return const PatientRegistryPanel(
      padding: EdgeInsets.zero,
    );
  }
}

class VisitWorkflowPage extends StatefulWidget {
  const VisitWorkflowPage({
    super.key,
    required this.state,
    required this.controller,
    this.session,
  });

  final ClinicState state;
  final ClinicController controller;
  final AuthSession? session;

  @override
  State<VisitWorkflowPage> createState() => _VisitWorkflowPageState();
}

class _VisitWorkflowPageState extends State<VisitWorkflowPage> {
  final TextEditingController _patientSearchController =
      TextEditingController();
  final TextEditingController _chiefComplaintController =
      TextEditingController();
  final TextEditingController _subjectiveController = TextEditingController();
  final TextEditingController _objectiveController = TextEditingController();
  final TextEditingController _assessmentController = TextEditingController();
  final TextEditingController _planController = TextEditingController();
  final TextEditingController _patientUpdateController =
      TextEditingController();
  final TextEditingController _transcriptController = TextEditingController();
  final TextEditingController _consentNotesController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  final AudioRecorder _audioRecorder = AudioRecorder();
  late final OfflineTranscriber _transcriber;

  String? _selectedPatientId;
  String? _selectedTemplateId;
  String _recordingConsentMethod = 'verbal';
  bool _speechReady = false;
  bool _isListening = false;
  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _privacyNoticeAcknowledged = false;
  bool _recordingConsentObtained = false;
  bool _aiTranscriptionConsentObtained = false;
  String _speechStatus = 'Speech dictation not initialized';
  String _dictationHint =
      'Use short live dictation for brief notes and Whisper offline for longer consult audio.';
  String _liveBaseTranscript = '';
  DateTime? _recordingStartedAt;
  String? _draftVisitId;
  final List<DictationCapture> _pendingDictations = <DictationCapture>[];

  @override
  void initState() {
    super.initState();
    _transcriber = createOfflineTranscriber();
    _initializeSpeech();
  }

  @override
  void dispose() {
    _patientSearchController.dispose();
    _chiefComplaintController.dispose();
    _subjectiveController.dispose();
    _objectiveController.dispose();
    _assessmentController.dispose();
    _planController.dispose();
    _patientUpdateController.dispose();
    _transcriptController.dispose();
    _consentNotesController.dispose();
    _audioRecorder.dispose();
    _speechToText.stop();
    super.dispose();
  }

  PatientRecord? get _selectedPatient {
    final patientId = _selectedPatientId;
    if (patientId == null) {
      return null;
    }

    for (final patient in widget.state.patients) {
      if (patient.id == patientId) {
        return patient;
      }
    }

    return null;
  }

  NoteTemplateRecord? get _selectedTemplate {
    final templateId = _selectedTemplateId;
    if (templateId == null) {
      return null;
    }

    for (final template in widget.state.templates) {
      if (template.id == templateId) {
        return template;
      }
    }

    return null;
  }

  Future<void> _initializeSpeech() async {
    try {
      final ready = await _speechToText.initialize(
        onStatus: (status) {
          if (!mounted) {
            return;
          }
          setState(() {
            _speechStatus = status;
            _isListening = status == SpeechToText.listeningStatus;
          });
        },
        onError: (error) {
          if (!mounted) {
            return;
          }
          setState(() {
            _speechStatus = error.errorMsg;
            _isListening = false;
          });
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _speechReady = ready;
        _speechStatus = ready
            ? 'Short dictation ready. Offline-only mode is requested when supported by the device.'
            : 'Speech recognizer unavailable on this device/browser.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _speechReady = false;
        _speechStatus = 'Speech initialization failed: $error';
      });
    }
  }

  Future<void> _toggleLiveDictation() async {
    if (!_speechReady) {
      _showSnackBar(_speechStatus);
      return;
    }

    if (_isListening) {
      await _speechToText.stop();
      if (!mounted) {
        return;
      }
      setState(() => _isListening = false);
      return;
    }

    if (!_ensureConsentReady(
      actionLabel: 'starting short dictation',
      requireAiConsent: true,
    )) {
      return;
    }

    _liveBaseTranscript = _transcriptController.text.trim();

    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(minutes: 1),
        pauseFor: const Duration(seconds: 4),
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          onDevice: true,
          partialResults: true,
          cancelOnError: true,
          autoPunctuation: true,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isListening = true;
        _dictationHint = 'Live dictation is listening...';
      });
    } catch (error) {
      _showSnackBar('Short dictation could not start: $error');
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final chunk = result.recognizedWords.trim();
    final merged = [
      if (_liveBaseTranscript.isNotEmpty) _liveBaseTranscript,
      if (chunk.isNotEmpty) chunk,
    ].join('\n');

    _transcriptController.value = TextEditingValue(
      text: merged,
      selection: TextSelection.collapsed(offset: merged.length),
    );
  }

  Future<void> _toggleLongFormRecording() async {
    if (!_transcriber.isSupported) {
      _showSnackBar(_transcriber.engineLabel);
      return;
    }

    if (_isRecording) {
      final path = await _audioRecorder.stop();
      if (!mounted) {
        return;
      }

      setState(() => _isRecording = false);

      if (path == null || path.isEmpty) {
        _showSnackBar('No recording captured.');
        return;
      }

      final durationSeconds = _recordingStartedAt == null
          ? null
          : DateTime.now().difference(_recordingStartedAt!).inSeconds;

      await _transcribeRecording(path, durationSeconds: durationSeconds);
      return;
    }

    if (!_ensureConsentReady(
      actionLabel: 'starting long-form recording',
      requireAiConsent: true,
    )) {
      return;
    }

    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      _showSnackBar('Microphone permission is required for offline recording.');
      return;
    }

    try {
      final path = await createRecordingPath();
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1),
        path: path,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isRecording = true;
        _recordingStartedAt = DateTime.now();
        _dictationHint =
            'Recording longer consult for offline Whisper transcription...';
      });
    } catch (error) {
      _showSnackBar('Unable to start long-form recording: $error');
    }
  }

  Future<void> _transcribeRecording(String path, {int? durationSeconds}) async {
    setState(() {
      _isTranscribing = true;
      _dictationHint = 'Preparing Whisper offline model and transcribing...';
    });

    try {
      await _transcriber.ensureReady();
      final transcript = await _transcriber.transcribeAudio(
        path,
        language: 'en',
      );

      if (!mounted) {
        return;
      }

      if (transcript.trim().isEmpty) {
        setState(() {
          _isTranscribing = false;
          _dictationHint = 'Transcription finished, but no text was produced.';
        });
        return;
      }

      final existingTranscript = _transcriptController.text.trim();
      final merged = [
        if (existingTranscript.isNotEmpty) existingTranscript,
        if (transcript.trim().isNotEmpty) transcript.trim(),
      ].join('\n\n');

      _transcriptController.text = merged;
      _transcriptController.selection = TextSelection.collapsed(
        offset: merged.length,
      );

      if (_selectedPatient != null) {
        final dictation = DictationCapture(
          id: _uuid.v4(),
          visitId: _ensureDraftVisitId(),
          transcript: transcript,
          summary: _chiefComplaintController.text.trim().isEmpty
              ? null
              : _chiefComplaintController.text.trim(),
          durationSeconds: durationSeconds,
          locale: 'en',
          createdAt: DateTime.now(),
        );

        _pendingDictations.add(dictation);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isTranscribing = false;
        _dictationHint = 'Offline Whisper transcription added to the note.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isTranscribing = false;
        _dictationHint = 'Whisper offline transcription failed.';
      });
      _showSnackBar('Offline Whisper transcription failed: $error');
    }
  }

  VisitRecord _buildVisitPreview() {
    final template = _selectedTemplate;
    final now = DateTime.now();

    return VisitRecord(
      id: _ensureDraftVisitId(),
      patientId: _selectedPatientId!,
      clinicianId: widget.session?.user.id,
      noteTemplateId: template?.id,
      encounterType: (_selectedPatient?.visitsCount ?? 0) == 0
          ? 'new_patient'
          : 'follow_up',
      status: 'draft',
      chiefComplaint: _valueOrNull(_chiefComplaintController),
      subjective: _valueOrNull(_subjectiveController),
      objective: _valueOrNull(_objectiveController),
      assessment: _valueOrNull(_assessmentController),
      plan: _valueOrNull(_planController),
      patientUpdate: _valueOrNull(_patientUpdateController),
      transcript: _valueOrNull(_transcriptController),
      privacyNoticeAcknowledgedAt: _privacyNoticeAcknowledged ? now : null,
      recordingConsentObtainedAt: _recordingConsentObtained ? now : null,
      recordingConsentMethod: _recordingConsentObtained
          ? _recordingConsentMethod
          : null,
      aiTranscriptionConsentObtainedAt: _aiTranscriptionConsentObtained
          ? now
          : null,
      consentNotes: _valueOrNull(_consentNotesController),
      conversationSummary: _valueOrNull(_transcriptController),
      templateSnapshot: template == null
          ? null
          : {
              'id': template.id,
              'title': template.title,
              'specialty': template.specialty,
            },
      startedAt: DateTime.now(),
      completedAt: DateTime.now(),
      syncedAt: DateTime.now(),
      meta: {
        'source': 'flutter-scaffold',
        'whisper_engine': _transcriber.engineLabel,
        'privacy_notice_version': widget.session?.security.privacyNoticeVersion,
        'recording_requires_consent':
            widget.session?.security.recordingRequiresConsent,
        'dictation_requested':
            _transcriptController.text.trim().isNotEmpty ||
            _pendingDictations.isNotEmpty,
        'processed_offline': _pendingDictations.isNotEmpty,
        'transcription_mode':
            _pendingDictations.isNotEmpty ||
                _transcriptController.text.trim().isNotEmpty
            ? 'offline_or_on_device'
            : null,
      },
    );
  }

  Future<void> _saveVisit() async {
    final selectedPatientId = _selectedPatientId;
    if (selectedPatientId == null) {
      _showSnackBar('Select or create a patient first.');
      return;
    }

    if (!_validateConsentBeforeSave()) {
      return;
    }

    final visit = _buildVisitPreview();

    await widget.controller.saveVisit(visit);

    for (final dictation in List<DictationCapture>.from(_pendingDictations)) {
      await widget.controller.saveDictation(
        dictation.copyWith(visitId: visit.id),
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _chiefComplaintController.clear();
      _subjectiveController.clear();
      _objectiveController.clear();
      _assessmentController.clear();
      _planController.clear();
      _patientUpdateController.clear();
      _transcriptController.clear();
      _consentNotesController.clear();
      _privacyNoticeAcknowledged = false;
      _recordingConsentObtained = false;
      _aiTranscriptionConsentObtained = false;
      _recordingConsentMethod = 'verbal';
      _dictationHint = 'Visit saved. Ready for the next encounter.';
      _draftVisitId = null;
      _pendingDictations.clear();
    });

    _showSnackBar('Visit saved locally and queued for sync.');
  }

  void _selectPatient(PatientRecord patient) {
    setState(() {
      _selectedPatientId = patient.id;
      _patientSearchController.text = patient.fullName;
      _draftVisitId = null;
      _pendingDictations.clear();
      _privacyNoticeAcknowledged = false;
      _recordingConsentObtained = false;
      _aiTranscriptionConsentObtained = false;
      _recordingConsentMethod = 'verbal';
      _consentNotesController.clear();
    });
    widget.controller.loadPatientHistory(patient.id);
  }

  String _ensureDraftVisitId() {
    return _draftVisitId ??= _uuid.v4();
  }

  bool _validateConsentBeforeSave() {
    final hasTranscriptOrDictation =
        _transcriptController.text.trim().isNotEmpty ||
        _pendingDictations.isNotEmpty;

    if (!hasTranscriptOrDictation) {
      return true;
    }

    return _ensureConsentReady(
      actionLabel: 'saving a dictated visit',
      requireAiConsent: true,
    );
  }

  bool _ensureConsentReady({
    required String actionLabel,
    required bool requireAiConsent,
  }) {
    if (!_privacyNoticeAcknowledged) {
      _showSnackBar('Acknowledge the privacy notice before $actionLabel.');
      return false;
    }

    if (!_recordingConsentObtained) {
      _showSnackBar('Capture recording consent before $actionLabel.');
      return false;
    }

    if (_recordingConsentMethod.trim().isEmpty) {
      _showSnackBar('Select how consent was captured before $actionLabel.');
      return false;
    }

    if (requireAiConsent && !_aiTranscriptionConsentObtained) {
      _showSnackBar('Capture AI transcription consent before $actionLabel.');
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final results = widget.state.patients.where((patient) {
      final query = _patientSearchController.text.trim().toLowerCase();
      if (query.isEmpty) {
        return true;
      }
      return patient.fullName.toLowerCase().contains(query) ||
          patient.medicalRecordNumber.toLowerCase().contains(query);
    }).toList()..sort((a, b) => a.fullName.compareTo(b.fullName));

    final visitHistory = _selectedPatientId == null
        ? const <VisitRecord>[]
        : widget.state.visitsForPatient(_selectedPatientId!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Doctor encounter workflow',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Use one screen to identify the patient, review prior visits, dictate short notes, and capture longer consult audio for offline Whisper transcription.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        _SectionCard(
          title: '1. Patient lookup or new registration',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _patientSearchController,
                      decoration: const InputDecoration(
                        labelText: 'Lookup patient by name or MRN',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (value) {
                        widget.controller.searchPatients(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () {
                      widget.controller.searchPatients(
                        _patientSearchController.text,
                      );
                    },
                    child: const Text('Search API'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () async {
                      final patient = await _showPatientDialog(
                        context,
                        widget.controller,
                      );
                      if (patient == null) {
                        return;
                      }
                      await widget.controller.savePatient(patient);
                      if (!mounted) {
                        return;
                      }
                      _selectPatient(patient);
                    },
                    child: const Text('New patient'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_selectedPatient != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.person_outline)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedPatient!.fullName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(_selectedPatient!.medicalRecordNumber),
                            Text(
                              'History: ${_selectedPatient!.medicalHistory.isEmpty ? 'No history yet' : _selectedPatient!.medicalHistory.join(', ')}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final patient = results[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(patient.fullName),
                        subtitle: Text(patient.medicalRecordNumber),
                        trailing: Text('${patient.visitsCount} visits'),
                        selected: _selectedPatientId == patient.id,
                        onTap: () => _selectPatient(patient),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _SectionCard(
          title: '2. Returning patient history',
          child: visitHistory.isEmpty
              ? const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.history_toggle_off),
                  title: Text(
                    'No prior visits loaded for the selected patient.',
                  ),
                )
              : Column(
                  children: visitHistory.take(6).map((visit) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_note_outlined),
                      title: Text(visit.chiefComplaint ?? 'Clinical note'),
                      subtitle: Text(
                        visit.assessment ?? visit.plan ?? visit.status,
                      ),
                      trailing: Text(_formatDateTime(visit.startedAt)),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 20),
        _SectionCard(
          title: '3. Encounter note, dictation, and transcript',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue:
                    widget.state.templates.any(
                      (item) => item.id == _selectedTemplateId,
                    )
                    ? _selectedTemplateId
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Clinical note template',
                ),
                items: widget.state.templates.map((template) {
                  return DropdownMenuItem<String>(
                    value: template.id,
                    child: Text(
                      '${template.title}${template.specialty == null ? '' : ' · ${template.specialty}'}',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedTemplateId = value);
                },
              ),
              const SizedBox(height: 16),
              _AdaptiveFields(
                children: [
                  TextField(
                    controller: _chiefComplaintController,
                    decoration: const InputDecoration(
                      labelText: 'Chief complaint',
                    ),
                  ),
                  TextField(
                    controller: _patientUpdateController,
                    decoration: const InputDecoration(
                      labelText: 'Patient update / advice summary',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _subjectiveController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Subjective'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _objectiveController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Objective'),
              ),
              const SizedBox(height: 12),
              _AdaptiveFields(
                children: [
                  TextField(
                    controller: _assessmentController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'Assessment'),
                  ),
                  TextField(
                    controller: _planController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'Plan'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'POPIA privacy and consent',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Confirm privacy notice acknowledgement and explicit consent before recording or storing AI-assisted transcripts.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (widget.session?.security.privacyNoticeVersion !=
                        null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Privacy notice version ${widget.session!.security.privacyNoticeVersion}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 12),
                    CheckboxListTile.adaptive(
                      value: _privacyNoticeAcknowledged,
                      onChanged: (value) {
                        setState(() {
                          _privacyNoticeAcknowledged = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Privacy notice explained and acknowledged',
                      ),
                      subtitle: const Text(
                        'Patient understands why clinical data is processed and stored.',
                      ),
                    ),
                    CheckboxListTile.adaptive(
                      value: _recordingConsentObtained,
                      onChanged: (value) {
                        setState(() {
                          _recordingConsentObtained = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Consent captured for recording / dictation',
                      ),
                      subtitle: const Text(
                        'Required before short dictation or long-form consult capture.',
                      ),
                    ),
                    CheckboxListTile.adaptive(
                      value: _aiTranscriptionConsentObtained,
                      onChanged: (value) {
                        setState(() {
                          _aiTranscriptionConsentObtained = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Consent captured for AI/offline transcription',
                      ),
                      subtitle: const Text(
                        'Required before Whisper or on-device transcription is persisted.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _recordingConsentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Consent capture method',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'verbal',
                          child: Text('Verbal'),
                        ),
                        DropdownMenuItem(
                          value: 'written',
                          child: Text('Written'),
                        ),
                        DropdownMenuItem(
                          value: 'digital',
                          child: Text('Digital form'),
                        ),
                        DropdownMenuItem(
                          value: 'guardian',
                          child: Text('Guardian / proxy'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => _recordingConsentMethod = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _consentNotesController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Consent notes',
                        hintText:
                            'Optional detail, for example patient asked that recording remain on the device only.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _toggleLiveDictation,
                    icon: Icon(_isListening ? Icons.stop : Icons.mic),
                    label: Text(
                      _isListening
                          ? 'Stop short dictation'
                          : 'Start short dictation',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isTranscribing
                        ? null
                        : _toggleLongFormRecording,
                    icon: Icon(
                      _isRecording
                          ? Icons.stop_circle_outlined
                          : Icons.mic_external_on_outlined,
                    ),
                    label: Text(
                      _isRecording
                          ? 'Stop long consult recording'
                          : 'Record long consult · Whisper offline',
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _saveVisit,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save visit'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(_speechStatus, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                _dictationHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _transcriptController,
                minLines: 8,
                maxLines: 14,
                decoration: InputDecoration(
                  labelText: 'Transcript / dictated conversation',
                  suffixIcon: _isTranscribing
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
              if (_selectedTemplate != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Template preview · ${_selectedTemplate!.title}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(_selectedTemplate!.templateBody),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class TemplatesPage extends StatelessWidget {
  const TemplatesPage({
    super.key,
    required this.state,
    required this.controller,
  });

  final ClinicState state;
  final ClinicController controller;

  @override
  Widget build(BuildContext context) {
    final templates = [...state.templates]
      ..sort((a, b) => a.title.compareTo(b.title));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Clinical templates',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Seed SOAP and specialty note templates early so dictated text lands inside a predictable structure.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        _SectionCard(
          title: 'Template library',
          trailing: OutlinedButton.icon(
            onPressed: () async {
              final template = await _showTemplateDialog(context);
              if (template == null) {
                return;
              }
              await controller.saveTemplate(template);
            },
            icon: const Icon(Icons.add),
            label: const Text('New template'),
          ),
          child: Column(
            children: templates.map((template) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.description_outlined),
                  ),
                  title: Text(template.title),
                  subtitle: Text(
                    '${template.specialty ?? 'General'} • ${template.sections.join(', ')}',
                  ),
                  isThreeLine: true,
                  trailing: template.isSystem
                      ? const Chip(label: Text('System'))
                      : const Chip(label: Text('Custom')),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class SyncPage extends StatelessWidget {
  const SyncPage({super.key, required this.state, required this.controller});

  final ClinicState state;
  final ClinicController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sync center', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'The Flutter client runs offline-first. Queue entries below are replayed to the Laravel API when a connection is available.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        _SectionCard(
          title: 'Current status',
          trailing: FilledButton.icon(
            onPressed: state.isSyncing ? null : controller.syncNow,
            icon: const Icon(Icons.sync),
            label: Text(state.isSyncing ? 'Syncing...' : 'Sync now'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusRow(label: 'API base URL', value: AppConfig.apiBaseUrl),
              _StatusRow(
                label: 'Last sync',
                value: _formatDateTime(state.lastSyncedAt),
              ),
              _StatusRow(
                label: 'Pending operations',
                value: state.queue.length.toString(),
              ),
              _StatusRow(label: 'Status', value: state.syncMessage ?? 'Idle'),
              const SizedBox(height: 12),
              Text(
                'Whisper offline is wired for native device builds. Web builds still share the same patient, visit, and template workflow, but long-form on-device Whisper remains disabled there.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _SectionCard(
          title: 'Pending queue',
          child: state.queue.isEmpty
              ? const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.check_circle_outline),
                  title: Text('Queue is empty.'),
                  subtitle: Text(
                    'Local changes have either synced or none have been created yet.',
                  ),
                )
              : Column(
                  children: state.queue.map((task) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.cloud_upload_outlined),
                      title: Text(task.operation.name),
                      subtitle: Text(task.entityId),
                      trailing: Text(_formatDateTime(task.createdAt)),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 20),
        _SectionCard(
          title: 'Local snapshot',
          child: SelectableText(
            state.exportDebugJson(),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 16),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                trailing ?? const SizedBox.shrink(),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _WorkflowStep extends StatelessWidget {
  const _WorkflowStep({
    required this.step,
    required this.title,
    required this.body,
  });

  final String step;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(child: Text(step)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdaptiveFields extends StatelessWidget {
  const _AdaptiveFields({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return Column(
            children:
                children
                    .expand((child) => [child, const SizedBox(height: 12)])
                    .toList()
                  ..removeLast(),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index < children.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

Future<PatientRecord?> _showPatientDialog(
  BuildContext context,
  ClinicController controller,
) async {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final allergiesController = TextEditingController();
  final medicationsController = TextEditingController();
  final historyController = TextEditingController();
  DateTime? selectedDob;
  String? sex;
  PatientRecord? result;

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('New patient record'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lastNameController,
                      decoration: const InputDecoration(labelText: 'Last name'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: sex,
                            decoration: const InputDecoration(labelText: 'Sex'),
                            items: const [
                              DropdownMenuItem(
                                value: 'female',
                                child: Text('Female'),
                              ),
                              DropdownMenuItem(
                                value: 'male',
                                child: Text('Male'),
                              ),
                              DropdownMenuItem(
                                value: 'other',
                                child: Text('Other'),
                              ),
                            ],
                            onChanged: (value) => setState(() => sex = value),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final dob = await showDatePicker(
                                context: context,
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                                initialDate: DateTime(1990),
                              );
                              if (dob == null) {
                                return;
                              }
                              setState(() => selectedDob = dob);
                            },
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(
                              selectedDob == null
                                  ? 'Date of birth'
                                  : DateFormat(
                                      'dd MMM yyyy',
                                    ).format(selectedDob!),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: allergiesController,
                      decoration: const InputDecoration(
                        labelText: 'Allergies (comma separated)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: medicationsController,
                      decoration: const InputDecoration(
                        labelText: 'Medications (comma separated)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: historyController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Medical history (comma separated)',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (firstNameController.text.trim().isEmpty ||
                      lastNameController.text.trim().isEmpty) {
                    return;
                  }

                  result = controller.repository.buildPatient(
                    firstName: firstNameController.text.trim(),
                    lastName: lastNameController.text.trim(),
                    dateOfBirth: selectedDob,
                    sex: sex,
                    phone: phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    email: emailController.text.trim().isEmpty
                        ? null
                        : emailController.text.trim(),
                    allergies: _splitCsv(allergiesController.text),
                    medications: _splitCsv(medicationsController.text),
                    medicalHistory: _splitCsv(historyController.text),
                  );

                  Navigator.of(context).pop();
                },
                child: const Text('Create patient'),
              ),
            ],
          );
        },
      );
    },
  );

  firstNameController.dispose();
  lastNameController.dispose();
  phoneController.dispose();
  emailController.dispose();
  allergiesController.dispose();
  medicationsController.dispose();
  historyController.dispose();

  return result;
}

Future<NoteTemplateRecord?> _showTemplateDialog(BuildContext context) async {
  final titleController = TextEditingController();
  final specialtyController = TextEditingController();
  final sectionsController = TextEditingController();
  final bodyController = TextEditingController();
  NoteTemplateRecord? result;

  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('New clinical template'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Template title',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: specialtyController,
                  decoration: const InputDecoration(labelText: 'Specialty'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sectionsController,
                  decoration: const InputDecoration(
                    labelText: 'Sections (comma separated)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyController,
                  minLines: 8,
                  maxLines: 14,
                  decoration: const InputDecoration(labelText: 'Template body'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty ||
                  bodyController.text.trim().isEmpty) {
                return;
              }

              result = NoteTemplateRecord(
                id: _uuid.v4(),
                title: titleController.text.trim(),
                specialty: specialtyController.text.trim().isEmpty
                    ? null
                    : specialtyController.text.trim(),
                templateBody: bodyController.text.trim(),
                sections: _splitCsv(sectionsController.text),
                isSystem: false,
              );

              Navigator.of(context).pop();
            },
            child: const Text('Save template'),
          ),
        ],
      );
    },
  );

  titleController.dispose();
  specialtyController.dispose();
  sectionsController.dispose();
  bodyController.dispose();

  return result;
}

List<String> _splitCsv(String input) {
  return input
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();
}

String? _valueOrNull(TextEditingController controller) {
  final value = controller.text.trim();
  return value.isEmpty ? null : value;
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return '—';
  }

  return DateFormat('dd MMM yyyy · HH:mm').format(value.toLocal());
}

PatientRecord? _patientById(List<PatientRecord> patients, String patientId) {
  for (final patient in patients) {
    if (patient.id == patientId) {
      return patient;
    }
  }

  return null;
}
