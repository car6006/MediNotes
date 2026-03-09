import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/router.dart';
import '../../../dictation/presentation/screens/dictation_capture_screen.dart';
import '../../../notes/presentation/screens/note_editor_screen.dart';
import '../../../notes/presentation/screens/note_versions_screen.dart';
import '../../../transcription/presentation/screens/transcript_review_screen.dart';
import '../../domain/entities/encounter.dart';
import '../controllers/encounters_controller.dart';

class EncounterDetailRouteArgs {
  const EncounterDetailRouteArgs({
    required this.encounterId,
    this.patientName,
  });

  final String encounterId;
  final String? patientName;
}

class EncounterDetailScreen extends ConsumerStatefulWidget {
  const EncounterDetailScreen({
    super.key,
    required this.encounterId,
    this.patientName,
  });

  final String encounterId;
  final String? patientName;

  @override
  ConsumerState<EncounterDetailScreen> createState() => _EncounterDetailScreenState();
}

class _EncounterDetailScreenState extends ConsumerState<EncounterDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(encountersControllerProvider.notifier).openEncounter(widget.encounterId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final encountersAsync = ref.watch(encountersControllerProvider);
    final fallbackState = encountersAsync.valueOrNull;
    final encounter = fallbackState?.selectedEncounter?.id == widget.encounterId
        ? fallbackState?.selectedEncounter
        : fallbackState?.encounters.cast<Encounter?>().firstWhere(
              (item) => item?.id == widget.encounterId,
              orElse: () => null,
            );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patientName?.trim().isNotEmpty == true
            ? 'Encounter · ${widget.patientName}'
            : 'Encounter detail'),
        actions: [
          IconButton(
            tooltip: 'Refresh encounter',
            onPressed: () => ref.read(encountersControllerProvider.notifier).openEncounter(widget.encounterId),
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: encountersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (state) {
          final currentEncounter = encounter;
          if (currentEncounter == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('The requested encounter could not be loaded.'),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.isLoadingDetail || state.isSaving)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(),
                  ),
                _EncounterHeaderCard(encounter: currentEncounter),
                const SizedBox(height: 16),
                _EncounterActionCard(
                  encounter: currentEncounter,
                  onMarkInProgress: currentEncounter.status == 'created'
                      ? () => ref.read(encountersControllerProvider.notifier).updateEncounterStatus(
                            currentEncounter.id,
                            'in_progress',
                          )
                      : null,
                  onOpenDictation: () => _openRoute(
                        AppRouter.dictationCapture,
                        DictationCaptureRouteArgs(
                          encounterId: currentEncounter.id,
                          patientName: currentEncounter.patient?.fullName ?? widget.patientName,
                        ),
                      ),
                  onOpenTranscripts: () => _openRoute(
                        AppRouter.transcriptReview,
                        TranscriptReviewRouteArgs(
                          encounterId: currentEncounter.id,
                          patientName: currentEncounter.patient?.fullName ?? widget.patientName,
                        ),
                      ),
                  onOpenNoteEditor: () => _openRoute(
                        AppRouter.noteEditor,
                        NoteEditorRouteArgs(
                          encounterId: currentEncounter.id,
                          patientName: currentEncounter.patient?.fullName ?? widget.patientName,
                        ),
                      ),
                  onOpenVersions: currentEncounter.currentClinicalNote == null
                      ? null
                      : () => _openRoute(
                            AppRouter.noteVersions,
                            NoteVersionsRouteArgs(
                              encounterId: currentEncounter.id,
                              noteId: currentEncounter.currentClinicalNote!.id,
                              patientName: currentEncounter.patient?.fullName ?? widget.patientName,
                            ),
                          ),
                  onCompleteEncounter: currentEncounter.canComplete && !currentEncounter.isCompleted
                      ? () => ref.read(encountersControllerProvider.notifier).updateEncounterStatus(
                            currentEncounter.id,
                            'completed',
                          )
                      : null,
                ),
                const SizedBox(height: 16),
                _EncounterSummaryGrid(encounter: currentEncounter),
                const SizedBox(height: 16),
                _TranscriptPreviewCard(encounter: currentEncounter),
                const SizedBox(height: 16),
                _ClinicalNotePreviewCard(encounter: currentEncounter),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openRoute(String route, Object arguments) async {
    await Navigator.of(context).pushNamed(route, arguments: arguments);
    if (!mounted) {
      return;
    }

    await ref.read(encountersControllerProvider.notifier).openEncounter(widget.encounterId);
  }
}

class _EncounterHeaderCard extends StatelessWidget {
  const _EncounterHeaderCard({required this.encounter});

  final Encounter encounter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startedAt = encounter.timeline.startedAt ?? encounter.createdAt;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        encounter.patient?.fullName ?? encounter.patientId,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        encounter.chiefComplaint?.trim().isNotEmpty == true
                            ? encounter.chiefComplaint!
                            : 'No chief complaint recorded yet.',
                      ),
                    ],
                  ),
                ),
                Chip(label: Text(_statusTitle(encounter.status))),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetaPill(
                  icon: Icons.schedule_outlined,
                  label: startedAt == null
                      ? 'Awaiting start time'
                      : DateFormat('dd MMM yyyy · HH:mm').format(startedAt.toLocal()),
                ),
                if (encounter.provider?.fullName?.trim().isNotEmpty ?? false)
                  _MetaPill(
                    icon: Icons.badge_outlined,
                    label: encounter.provider!.fullName!,
                  ),
                if (encounter.template?.title?.trim().isNotEmpty ?? false)
                  _MetaPill(
                    icon: Icons.description_outlined,
                    label: encounter.template!.title!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EncounterActionCard extends StatelessWidget {
  const _EncounterActionCard({
    required this.encounter,
    this.onMarkInProgress,
    required this.onOpenDictation,
    required this.onOpenTranscripts,
    required this.onOpenNoteEditor,
    this.onOpenVersions,
    this.onCompleteEncounter,
  });

  final Encounter encounter;
  final VoidCallback? onMarkInProgress;
  final VoidCallback onOpenDictation;
  final VoidCallback onOpenTranscripts;
  final VoidCallback onOpenNoteEditor;
  final VoidCallback? onOpenVersions;
  final VoidCallback? onCompleteEncounter;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phase 4 encounter workflow', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (onMarkInProgress != null)
                  FilledButton.icon(
                    onPressed: onMarkInProgress,
                    icon: const Icon(Icons.play_arrow_outlined),
                    label: const Text('Mark in progress'),
                  ),
                FilledButton.tonalIcon(
                  onPressed: onOpenDictation,
                  icon: const Icon(Icons.mic_none_outlined),
                  label: const Text('Dictation capture'),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenTranscripts,
                  icon: const Icon(Icons.subtitles_outlined),
                  label: const Text('Transcript review'),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenNoteEditor,
                  icon: const Icon(Icons.edit_note_outlined),
                  label: const Text('Note editor'),
                ),
                if (onOpenVersions != null)
                  OutlinedButton.icon(
                    onPressed: onOpenVersions,
                    icon: const Icon(Icons.history_outlined),
                    label: const Text('Note versions'),
                  ),
                if (onCompleteEncounter != null)
                  FilledButton.icon(
                    onPressed: onCompleteEncounter,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Complete encounter'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EncounterSummaryGrid extends StatelessWidget {
  const _EncounterSummaryGrid({required this.encounter});

  final Encounter encounter;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _SummaryCard(
          title: 'Counts',
          lines: [
            'Audio files: ${encounter.counts.audioFiles}',
            'Transcripts: ${encounter.counts.transcripts}',
            'Current note: ${encounter.currentClinicalNote == null ? 'Not started' : _statusTitle(encounter.currentClinicalNote!.status)}',
          ],
        ),
        _SummaryCard(
          title: 'Consent',
          lines: [
            'Privacy notice: ${encounter.consent.privacyNoticeAcknowledgedAt == null ? 'Pending' : 'Captured'}',
            'Recording consent: ${encounter.consent.hasRecordingConsent ? 'Captured' : 'Pending'}',
            'AI consent: ${encounter.consent.hasAiConsent ? 'Captured' : 'Pending'}',
          ],
        ),
        _SummaryCard(
          title: 'Timeline',
          lines: [
            'In progress: ${_formatDate(encounter.timeline.inProgressAt)}',
            'Dictation captured: ${_formatDate(encounter.timeline.dictationCapturedAt)}',
            'Signed off: ${_formatDate(encounter.timeline.signedOffAt)}',
          ],
        ),
      ],
    );
  }
}

class _TranscriptPreviewCard extends StatelessWidget {
  const _TranscriptPreviewCard({required this.encounter});

  final Encounter encounter;

  @override
  Widget build(BuildContext context) {
    final latestTranscript = encounter.transcripts.isNotEmpty ? encounter.transcripts.first : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transcript preview', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              latestTranscript?.content.trim().isNotEmpty == true
                  ? latestTranscript!.content
                  : encounter.compatibilityNote.transcript?.trim().isNotEmpty == true
                      ? encounter.compatibilityNote.transcript!
                      : 'No transcript has been captured yet.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ClinicalNotePreviewCard extends StatelessWidget {
  const _ClinicalNotePreviewCard({required this.encounter});

  final Encounter encounter;

  @override
  Widget build(BuildContext context) {
    final note = encounter.currentClinicalNote;
    final sections = note?.currentVersion?.sections ?? const [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clinical note preview', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (note == null)
              const Text('No clinical note has been started yet.')
            else ...[
              Text('Status: ${_statusTitle(note.status)} · version ${note.currentVersionNumber}'),
              const SizedBox(height: 12),
              if (sections.isEmpty)
                const Text('No note sections have been captured yet.')
              else
                ...sections.take(4).map(
                  (section) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(section.label, style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(section.content?.trim().isNotEmpty == true ? section.content! : '—'),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(line),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

String _statusTitle(String value) {
  return value
      .split('_')
      .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _formatDate(DateTime? value) {
  if (value == null) {
    return '—';
  }

  return DateFormat('dd MMM yyyy · HH:mm').format(value.toLocal());
}