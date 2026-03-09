import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../encounters/presentation/controllers/encounters_controller.dart';
import '../../domain/entities/clinical_note.dart';

class NoteVersionsRouteArgs {
  const NoteVersionsRouteArgs({
    required this.encounterId,
    required this.noteId,
    this.patientName,
  });

  final String encounterId;
  final String noteId;
  final String? patientName;
}

class NoteVersionsScreen extends ConsumerStatefulWidget {
  const NoteVersionsScreen({
    super.key,
    required this.encounterId,
    required this.noteId,
    this.patientName,
  });

  final String encounterId;
  final String noteId;
  final String? patientName;

  @override
  ConsumerState<NoteVersionsScreen> createState() => _NoteVersionsScreenState();
}

class _NoteVersionsScreenState extends ConsumerState<NoteVersionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(encountersControllerProvider.notifier).loadNoteVersions(widget.noteId);
    });
  }

  @override
  void dispose() {
    ref.read(encountersControllerProvider.notifier).clearNoteVersions();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final encountersState = ref.watch(encountersControllerProvider).valueOrNull;
    final versions = encountersState?.noteVersions ?? const <ClinicalNoteVersion>[];
    final isLoading = encountersState?.isLoadingDetail ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.patientName?.trim().isNotEmpty == true
              ? 'Note versions · ${widget.patientName}'
              : 'Clinical note versions',
        ),
      ),
      body: isLoading && versions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : versions.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No note versions are available for this encounter yet.'),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: versions.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final version = versions[index];
                    return Card(
                      child: ExpansionTile(
                        title: Text('Version ${version.versionNumber} · ${_sourceTitle(version.source)}'),
                        subtitle: Text(
                          version.createdAt == null
                              ? 'Created time unavailable'
                              : DateFormat('dd MMM yyyy · HH:mm').format(version.createdAt!.toLocal()),
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(label: Text(version.isLocked ? 'Locked' : 'Editable')),
                              if (version.signedAt != null)
                                Chip(
                                  label: Text(
                                    'Signed ${DateFormat('dd MMM').format(version.signedAt!.toLocal())}',
                                  ),
                                ),
                            ],
                          ),
                          if (version.changeSummary?.trim().isNotEmpty ?? false) ...[
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Change summary: ${version.changeSummary}'),
                            ),
                          ],
                          const SizedBox(height: 12),
                          ...version.sections.map(
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
                      ),
                    );
                  },
                ),
    );
  }

  String _sourceTitle(String value) {
    return value
        .split('_')
        .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}