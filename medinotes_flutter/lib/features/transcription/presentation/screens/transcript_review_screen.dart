import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../encounters/domain/entities/encounter.dart';
import '../../../encounters/presentation/controllers/encounters_controller.dart';
import '../../../notes/presentation/screens/note_editor_screen.dart';
import '../../domain/entities/transcript.dart';

class TranscriptReviewRouteArgs {
  const TranscriptReviewRouteArgs({
    required this.encounterId,
    this.patientName,
  });

  final String encounterId;
  final String? patientName;
}

class TranscriptReviewScreen extends ConsumerStatefulWidget {
  const TranscriptReviewScreen({
    super.key,
    required this.encounterId,
    this.patientName,
  });

  final String encounterId;
  final String? patientName;

  @override
  ConsumerState<TranscriptReviewScreen> createState() => _TranscriptReviewScreenState();
}

class _TranscriptReviewScreenState extends ConsumerState<TranscriptReviewScreen> {
  final TextEditingController _rawController = TextEditingController();
  final TextEditingController _cleanedController = TextEditingController();
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final encounter = await ref.read(encountersControllerProvider.notifier).openEncounter(widget.encounterId);
      _seedEncounterData(encounter);
    });
  }

  @override
  void dispose() {
    _rawController.dispose();
    _cleanedController.dispose();
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
              ? 'Transcript review · ${widget.patientName}'
              : 'Transcript review',
        ),
      ),
      body: encounter == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Raw transcript', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _rawController,
                            readOnly: true,
                            minLines: 8,
                            maxLines: 16,
                            decoration: const InputDecoration(
                              labelText: 'Raw transcript output',
                              alignLabelWithHint: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reviewed transcript', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed: () {
                                  setState(() {
                                    _cleanedController.text = _rawController.text.trim();
                                    _cleanedController.selection = TextSelection.collapsed(
                                      offset: _cleanedController.text.length,
                                    );
                                  });
                                },
                                icon: const Icon(Icons.copy_outlined),
                                label: const Text('Use raw transcript'),
                              ),
                              FilledButton.icon(
                                onPressed: _cleanedController.text.trim().isEmpty
                                    ? null
                                    : () => _saveCleanedTranscript(encounter),
                                icon: const Icon(Icons.save_outlined),
                                label: const Text('Save reviewed transcript'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => Navigator.of(context).pushNamed(
                                  AppRouter.noteEditor,
                                  arguments: NoteEditorRouteArgs(
                                    encounterId: encounter.id,
                                    patientName: widget.patientName ?? encounter.patient?.fullName,
                                  ),
                                ),
                                icon: const Icon(Icons.edit_note_outlined),
                                label: const Text('Open note editor'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _cleanedController,
                            onChanged: (_) => setState(() {}),
                            minLines: 8,
                            maxLines: 16,
                            decoration: const InputDecoration(
                              labelText: 'Cleaned transcript',
                              alignLabelWithHint: true,
                            ),
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
    if (_seeded) {
      return;
    }

    final raw = encounter.transcripts.cast<Transcript?>().firstWhere(
          (item) => item?.isRaw == true,
          orElse: () => null,
        );
    final cleaned = encounter.transcripts.cast<Transcript?>().firstWhere(
          (item) => item?.isCleaned == true,
          orElse: () => null,
        );

    _rawController.text = raw?.content ?? '';
    _cleanedController.text = cleaned?.content ?? raw?.content ?? '';
    _seeded = true;
  }

  Future<void> _saveCleanedTranscript(Encounter encounter) async {
    final latestRaw = encounter.transcripts.cast<Transcript?>().firstWhere(
          (item) => item?.isRaw == true,
          orElse: () => null,
        );

    try {
      await ref.read(encountersControllerProvider.notifier).saveTranscript(
            encounter.id,
            TranscriptDraft(
              transcriptType: 'cleaned',
              content: _cleanedController.text.trim(),
              sourceEngine: 'manual_review',
              language: 'en',
              audioFileId: latestRaw?.audioFileId,
            ),
          );

      final refreshed = await ref.read(encountersControllerProvider.notifier).openEncounter(encounter.id);
      _seeded = false;
      _seedEncounterData(refreshed);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reviewed transcript saved.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }
}