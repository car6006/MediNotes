import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../encounters/domain/entities/encounter.dart';
import '../../../encounters/presentation/controllers/encounters_controller.dart';
import '../../../templates/presentation/controllers/encounter_templates_controller.dart';
import '../../domain/entities/clinical_note.dart';
import 'note_versions_screen.dart';

class NoteEditorRouteArgs {
  const NoteEditorRouteArgs({
    required this.encounterId,
    this.patientName,
  });

  final String encounterId;
  final String? patientName;
}

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({
    super.key,
    required this.encounterId,
    this.patientName,
  });

  final String encounterId;
  final String? patientName;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final List<_EditableSection> _sections = <_EditableSection>[];
  bool _loadingSections = true;
  bool _seeded = false;
  String _status = 'draft';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final encounter = await ref.read(encountersControllerProvider.notifier).openEncounter(widget.encounterId);
      await _seedEncounterData(encounter);
    });
  }

  @override
  void dispose() {
    for (final section in _sections) {
      section.dispose();
    }
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
              ? 'Clinical note · ${widget.patientName}'
              : 'Clinical note editor',
        ),
      ),
      body: encounter == null || _loadingSections
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_errorMessage!),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (encounter.currentClinicalNote?.isSignedOff ?? false)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'This note is already signed off. Saving changes will create a new review version.',
                        ),
                      ),
                    ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Clinical note state', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: 320,
                            child: DropdownButtonFormField<String>(
                              initialValue: _status,
                              decoration: const InputDecoration(labelText: 'Note status'),
                              items: const [
                                DropdownMenuItem(value: 'draft', child: Text('Draft')),
                                DropdownMenuItem(
                                  value: 'doctor_review_pending',
                                  child: Text('Doctor review pending'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() => _status = value);
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              FilledButton.icon(
                                onPressed: () => _save(encounter),
                                icon: const Icon(Icons.save_outlined),
                                label: Text(encounter.currentClinicalNote == null ? 'Create note' : 'Save note'),
                              ),
                              if (encounter.currentClinicalNote != null)
                                OutlinedButton.icon(
                                  onPressed: encounter.currentClinicalNote!.isReviewPending
                                      ? () => _signNote(encounter)
                                      : null,
                                  icon: const Icon(Icons.verified_outlined),
                                  label: const Text('Sign note'),
                                ),
                              if (encounter.currentClinicalNote != null)
                                OutlinedButton.icon(
                                  onPressed: () => Navigator.of(context).pushNamed(
                                    AppRouter.noteVersions,
                                    arguments: NoteVersionsRouteArgs(
                                      encounterId: encounter.id,
                                      noteId: encounter.currentClinicalNote!.id,
                                      patientName: widget.patientName ?? encounter.patient?.fullName,
                                    ),
                                  ),
                                  icon: const Icon(Icons.history_outlined),
                                  label: const Text('Versions'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._sections.map(
                    (section) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(section.label, style: Theme.of(context).textTheme.titleLarge),
                              if (section.prompt?.trim().isNotEmpty ?? false) ...[
                                const SizedBox(height: 6),
                                Text(section.prompt!),
                              ],
                              const SizedBox(height: 12),
                              TextField(
                                controller: section.controller,
                                minLines: 4,
                                maxLines: 10,
                                decoration: InputDecoration(
                                  labelText: section.isRequired ? '${section.label} *' : section.label,
                                  alignLabelWithHint: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _seedEncounterData(Encounter encounter) async {
    if (_seeded) {
      return;
    }

    setState(() {
      _loadingSections = true;
      _errorMessage = null;
    });

    final note = encounter.currentClinicalNote;
    final sections = note?.currentVersion?.sections ?? await _defaultSectionsForEncounter(encounter);

    for (final section in _sections) {
      section.dispose();
    }
    _sections.clear();

    for (final section in sections) {
      _sections.add(
        _EditableSection(
          key: section.key,
          label: section.label,
          position: section.position,
          prompt: section.prompt,
          isRequired: section.isRequired,
          content: section.content,
        ),
      );
    }

    _status = note == null
        ? 'draft'
        : (note.isSignedOff ? 'doctor_review_pending' : note.status);

    if (!mounted) {
      return;
    }

    setState(() {
      _loadingSections = false;
      _seeded = true;
    });
  }

  Future<List<ClinicalNoteSection>> _defaultSectionsForEncounter(Encounter encounter) async {
    if (encounter.encounterTemplateId?.trim().isNotEmpty ?? false) {
      final template = await ref.read(encounterTemplatesRepositoryProvider).loadTemplate(
            encounter.encounterTemplateId!,
          );
      if (template != null && template.encounterSections.isNotEmpty) {
        return template.encounterSections
            .map(
              (section) => ClinicalNoteSection(
                key: section.key,
                label: section.label,
                position: section.position,
                prompt: section.prompt,
                isRequired: section.isRequired,
                content: section.defaultContent,
              ),
            )
            .toList();
      }

      if (template != null && template.sections.isNotEmpty) {
        return _sectionsFromLabels(template.sections);
      }
    }

    if (encounter.template?.sections.isNotEmpty ?? false) {
      return _sectionsFromLabels(encounter.template!.sections);
    }

    return _sectionsFromLabels(const ['Subjective', 'Objective', 'Assessment', 'Plan']);
  }

  List<ClinicalNoteSection> _sectionsFromLabels(List<String> labels) {
    return labels.asMap().entries.map((entry) {
      final label = entry.value;
      return ClinicalNoteSection(
        key: _slugify(label),
        label: label,
        position: entry.key + 1,
        isRequired: true,
      );
    }).toList();
  }

  Future<void> _save(Encounter encounter) async {
    try {
      final draft = ClinicalNoteDraft(
        status: _status,
        generateWithMedicAI: false,
        sections: _sections
            .map(
              (section) => ClinicalNoteSectionInput(
                key: section.key,
                label: section.label,
                position: section.position,
                prompt: section.prompt,
                isRequired: section.isRequired,
                content: section.controller.text.trim().isEmpty
                    ? null
                    : section.controller.text.trim(),
              ),
            )
            .toList(),
      );

      if (encounter.currentClinicalNote == null) {
        await ref.read(encountersControllerProvider.notifier).createClinicalNote(
              encounter.id,
              draft,
            );
      } else {
        await ref.read(encountersControllerProvider.notifier).updateClinicalNote(
              encounter.id,
              encounter.currentClinicalNote!.id,
              draft,
            );
      }

      final refreshed = await ref.read(encountersControllerProvider.notifier).openEncounter(encounter.id);
      _seeded = false;
      await _seedEncounterData(refreshed);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clinical note saved.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.toString());
    }
  }

  Future<void> _signNote(Encounter encounter) async {
    final note = encounter.currentClinicalNote;
    if (note == null) {
      return;
    }

    final controller = TextEditingController();
    final signatureStatement = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sign clinical note'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Signature statement (optional)',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Sign'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (signatureStatement == null) {
      return;
    }

    try {
      await ref.read(encountersControllerProvider.notifier).signClinicalNote(
            encounter.id,
            note.id,
            signatureStatement: signatureStatement,
          );

      final refreshed = await ref.read(encountersControllerProvider.notifier).openEncounter(encounter.id);
      _seeded = false;
      await _seedEncounterData(refreshed);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clinical note signed off.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.toString());
    }
  }

  String _slugify(String label) {
    return label
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}

class _EditableSection {
  _EditableSection({
    required this.key,
    required this.label,
    required this.position,
    this.prompt,
    required this.isRequired,
    String? content,
  }) : controller = TextEditingController(text: content ?? '');

  final String key;
  final String label;
  final int position;
  final String? prompt;
  final bool isRequired;
  final TextEditingController controller;

  void dispose() {
    controller.dispose();
  }
}