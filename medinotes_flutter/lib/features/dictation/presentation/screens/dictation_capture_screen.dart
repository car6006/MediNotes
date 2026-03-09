import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../app/offline_transcriber.dart';
import '../../../../app/recording_path.dart';
import '../../../../app/router.dart';
import '../../../encounters/domain/entities/encounter.dart';
import '../../../encounters/presentation/controllers/encounters_controller.dart';
import '../../../transcription/domain/entities/transcript.dart';
import '../../../transcription/presentation/screens/transcript_review_screen.dart';
import '../../domain/entities/encounter_audio_file.dart';

class DictationCaptureRouteArgs {
  const DictationCaptureRouteArgs({
    required this.encounterId,
    this.patientName,
  });

  final String encounterId;
  final String? patientName;
}

class DictationCaptureScreen extends ConsumerStatefulWidget {
  const DictationCaptureScreen({
    super.key,
    required this.encounterId,
    this.patientName,
  });

  final String encounterId;
  final String? patientName;

  @override
  ConsumerState<DictationCaptureScreen> createState() => _DictationCaptureScreenState();
}

class _DictationCaptureScreenState extends ConsumerState<DictationCaptureScreen> {
  final SpeechToText _speechToText = SpeechToText();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final TextEditingController _transcriptController = TextEditingController();

  late final OfflineTranscriber _transcriber;

  bool _speechReady = false;
  bool _isListening = false;
  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _seededTranscript = false;
  String _speechStatus = 'Speech dictation not initialized.';
  String _dictationHint = 'Use short live dictation or longer offline Whisper capture.';
  String _liveBaseTranscript = '';
  String? _recordingPath;
  DateTime? _recordingCapturedAt;
  DateTime? _recordingStartedAt;
  int? _recordingDurationSeconds;
  EncounterAudioFile? _registeredAudioFile;

  @override
  void initState() {
    super.initState();
    _transcriber = createOfflineTranscriber();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final encounter = await ref.read(encountersControllerProvider.notifier).openEncounter(widget.encounterId);
      _seedEncounterData(encounter);
    });
    _initializeSpeech();
  }

  @override
  void dispose() {
    _speechToText.cancel();
    _audioRecorder.dispose();
    _transcriptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final encountersState = ref.watch(encountersControllerProvider).valueOrNull;
    final encounter = encountersState?.selectedEncounter?.id == widget.encounterId
        ? encountersState?.selectedEncounter
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.patientName?.trim().isNotEmpty == true
              ? 'Dictation · ${widget.patientName}'
              : 'Dictation capture',
        ),
      ),
      body: encounter == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ConsentBanner(encounter: encounter),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Capture transcript',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              FilledButton.icon(
                                onPressed: _toggleLiveDictation,
                                icon: Icon(_isListening ? Icons.stop : Icons.keyboard_voice_outlined),
                                label: Text(
                                  _isListening ? 'Stop short dictation' : 'Start short dictation',
                                ),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: _isTranscribing ? null : _toggleLongFormRecording,
                                icon: Icon(_isRecording ? Icons.stop_circle_outlined : Icons.mic_outlined),
                                label: Text(
                                  _isRecording
                                      ? 'Stop long recording'
                                      : 'Record long consult · Whisper offline',
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _transcriptController.text.trim().isEmpty
                                    ? null
                                    : () => _saveRawTranscript(encounter),
                                icon: const Icon(Icons.save_outlined),
                                label: const Text('Save raw transcript'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => Navigator.of(context).pushNamed(
                                  AppRouter.transcriptReview,
                                  arguments: TranscriptReviewRouteArgs(
                                    encounterId: encounter.id,
                                    patientName: widget.patientName ?? encounter.patient?.fullName,
                                  ),
                                ),
                                icon: const Icon(Icons.subtitles_outlined),
                                label: const Text('Open transcript review'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(_speechStatus),
                          const SizedBox(height: 6),
                          Text(_dictationHint),
                          if (_isTranscribing) ...[
                            const SizedBox(height: 12),
                            const LinearProgressIndicator(),
                          ],
                          const SizedBox(height: 16),
                          TextField(
                            controller: _transcriptController,
                            decoration: const InputDecoration(
                              labelText: 'Raw transcript',
                              hintText: 'Short dictation and Whisper output will appear here.',
                              alignLabelWithHint: true,
                            ),
                            minLines: 8,
                            maxLines: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _seedEncounterData(Encounter encounter) {
    if (_seededTranscript) {
      return;
    }

    final rawTranscript = encounter.transcripts.cast<Transcript?>().firstWhere(
          (item) => item?.isRaw == true,
          orElse: () => null,
        );

    final seedText = rawTranscript?.content ?? encounter.compatibilityNote.transcript ?? '';
    _transcriptController.text = seedText;
    _registeredAudioFile = encounter.audioFiles.isNotEmpty ? encounter.audioFiles.first : null;
    _seededTranscript = true;
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
    final encounter = ref.read(encountersControllerProvider).valueOrNull?.selectedEncounter;
    if (encounter == null) {
      return;
    }

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

    if (!_ensureConsentReady(encounter, actionLabel: 'starting short dictation')) {
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
    final encounter = ref.read(encountersControllerProvider).valueOrNull?.selectedEncounter;
    if (encounter == null) {
      return;
    }

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

      _recordingPath = path;
      _recordingCapturedAt = DateTime.now();
      _recordingDurationSeconds = durationSeconds;
      await _transcribeRecording(path);
      return;
    }

    if (!_ensureConsentReady(encounter, actionLabel: 'starting long-form recording')) {
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
        _dictationHint = 'Recording longer consult for offline Whisper transcription...';
      });
    } catch (error) {
      _showSnackBar('Unable to start long-form recording: $error');
    }
  }

  Future<void> _transcribeRecording(String path) async {
    setState(() {
      _isTranscribing = true;
      _dictationHint = 'Preparing Whisper offline model and transcribing...';
    });

    try {
      await _transcriber.ensureReady();
      final transcript = await _transcriber.transcribeAudio(path, language: 'en');

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

      final existing = _transcriptController.text.trim();
      final merged = [
        if (existing.isNotEmpty) existing,
        transcript.trim(),
      ].join('\n\n');

      _transcriptController.text = merged;
      _transcriptController.selection = TextSelection.collapsed(offset: merged.length);

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
      _showSnackBar('Unable to transcribe recording: $error');
    }
  }

  Future<void> _saveRawTranscript(Encounter encounter) async {
    if (!_ensureConsentReady(encounter, actionLabel: 'saving a raw transcript')) {
      return;
    }

    try {
      EncounterAudioFile? audioFile = _registeredAudioFile;

      if ((_recordingPath?.trim().isNotEmpty ?? false) && audioFile == null) {
        audioFile = await ref.read(encountersControllerProvider.notifier).registerAudio(
              encounter.id,
              EncounterAudioRegistrationDraft(
                storagePath: _recordingPath!,
                originalFilename: _fileNameFromPath(_recordingPath!),
                mimeType: 'audio/mp4',
                durationSeconds: _recordingDurationSeconds,
                captureMode: 'offline_whisper',
                capturedAt: _recordingCapturedAt,
              ),
            );
        _registeredAudioFile = audioFile;
      }

      await ref.read(encountersControllerProvider.notifier).saveTranscript(
            encounter.id,
            TranscriptDraft(
              transcriptType: 'raw',
              content: _transcriptController.text.trim(),
              sourceEngine: audioFile == null ? 'speech_to_text' : 'offline_whisper',
              audioFileId: audioFile?.id,
              language: 'en',
            ),
          );

      if (!mounted) {
        return;
      }

      _showSnackBar('Raw transcript saved.');
    } catch (error) {
      _showSnackBar(error.toString());
    }
  }

  bool _ensureConsentReady(Encounter encounter, {required String actionLabel}) {
    if (encounter.consent.privacyNoticeAcknowledgedAt == null) {
      _showSnackBar('Acknowledge the privacy notice before $actionLabel.');
      return false;
    }

    if (!encounter.consent.hasRecordingConsent) {
      _showSnackBar('Capture recording consent before $actionLabel.');
      return false;
    }

    if (!encounter.consent.hasAiConsent) {
      _showSnackBar('Capture AI transcription consent before $actionLabel.');
      return false;
    }

    return true;
  }

  String _fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/');
    return segments.isEmpty ? path : segments.last;
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ConsentBanner extends StatelessWidget {
  const _ConsentBanner({required this.encounter});

  final Encounter encounter;

  @override
  Widget build(BuildContext context) {
    final allReady = encounter.consent.hasRecordingConsent && encounter.consent.hasAiConsent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: allReady
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            allReady ? 'Consent ready' : 'Consent needs attention',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Privacy notice: ${encounter.consent.privacyNoticeAcknowledgedAt == null ? 'pending' : 'captured'} · '
            'Recording consent: ${encounter.consent.hasRecordingConsent ? 'captured' : 'pending'} · '
            'AI consent: ${encounter.consent.hasAiConsent ? 'captured' : 'pending'}',
          ),
        ],
      ),
    );
  }
}