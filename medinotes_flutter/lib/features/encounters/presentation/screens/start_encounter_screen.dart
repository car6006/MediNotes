import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../templates/domain/entities/encounter_template.dart';
import '../../../templates/presentation/screens/template_picker_screen.dart';
import '../../domain/entities/encounter.dart';
import '../controllers/encounters_controller.dart';
import 'encounter_detail_screen.dart';

class StartEncounterRouteArgs {
  const StartEncounterRouteArgs({
    this.patientId,
    this.patientName,
    this.appointmentId,
    this.initialChiefComplaint,
  });

  final String? patientId;
  final String? patientName;
  final String? appointmentId;
  final String? initialChiefComplaint;
}

class StartEncounterScreen extends ConsumerStatefulWidget {
  const StartEncounterScreen({
    super.key,
    this.patientId,
    this.patientName,
    this.appointmentId,
    this.initialChiefComplaint,
  });

  final String? patientId;
  final String? patientName;
  final String? appointmentId;
  final String? initialChiefComplaint;

  @override
  ConsumerState<StartEncounterScreen> createState() => _StartEncounterScreenState();
}

class _StartEncounterScreenState extends ConsumerState<StartEncounterScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _providerIdController;
  late final TextEditingController _chiefComplaintController;
  late final TextEditingController _consentNotesController;

  EncounterTemplate? _selectedTemplate;
  String _encounterType = 'clinical_encounter';
  bool _privacyNoticeAcknowledged = true;
  bool _recordingConsentObtained = true;
  bool _aiConsentObtained = true;
  String _recordingConsentMethod = 'verbal';
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _providerIdController = TextEditingController();
    _chiefComplaintController = TextEditingController(
      text: widget.initialChiefComplaint ?? '',
    );
    _consentNotesController = TextEditingController();
  }

  @override
  void dispose() {
    _providerIdController.dispose();
    _chiefComplaintController.dispose();
    _consentNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start encounter')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patientName?.trim().isNotEmpty == true
                            ? 'Starting encounter for ${widget.patientName}'
                            : 'Prepare a new clinical encounter.',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Capture consent metadata up front, choose the encounter template, and hand off to dictation, transcript review, and note authoring screens.',
                        style: Theme.of(context).textTheme.bodyMedium,
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
                      Text('Encounter context', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: 280,
                            child: DropdownButtonFormField<String>(
                              initialValue: _encounterType,
                              decoration: const InputDecoration(labelText: 'Encounter type'),
                              items: const [
                                DropdownMenuItem(
                                  value: 'clinical_encounter',
                                  child: Text('Clinical encounter'),
                                ),
                                DropdownMenuItem(
                                  value: 'scheduled_consult',
                                  child: Text('Scheduled consult'),
                                ),
                                DropdownMenuItem(
                                  value: 'follow_up',
                                  child: Text('Follow-up'),
                                ),
                              ],
                              onChanged: _submitting
                                  ? null
                                  : (value) {
                                      if (value == null) {
                                        return;
                                      }
                                      setState(() => _encounterType = value);
                                    },
                            ),
                          ),
                          SizedBox(
                            width: 280,
                            child: TextFormField(
                              controller: _providerIdController,
                              decoration: const InputDecoration(
                                labelText: 'Provider ID (optional)',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _chiefComplaintController,
                        decoration: const InputDecoration(
                          labelText: 'Chief complaint',
                          hintText: 'Summarise the presenting concern.',
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Chief complaint is required.';
                          }
                          return null;
                        },
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
                      Text('Encounter template', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      if (_selectedTemplate == null)
                        const Text('No encounter template selected yet.')
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedTemplate!.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(
                                  label: Text(
                                    _selectedTemplate!.noteFormat?.toUpperCase() ?? 'SOAP',
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    '${_selectedTemplate!.encounterSections.length} sections',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: _submitting ? null : _pickTemplate,
                            icon: const Icon(Icons.description_outlined),
                            label: Text(
                              _selectedTemplate == null ? 'Choose template' : 'Change template',
                            ),
                          ),
                          if (_selectedTemplate != null)
                            TextButton.icon(
                              onPressed: _submitting
                                  ? null
                                  : () => setState(() => _selectedTemplate = null),
                              icon: const Icon(Icons.clear),
                              label: const Text('Clear template'),
                            ),
                        ],
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
                      Text('Consent readiness', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'The backend requires privacy notice acknowledgement, recording consent, and AI transcription consent before dictation and transcript capture can proceed.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: _privacyNoticeAcknowledged,
                        onChanged: _submitting
                            ? null
                            : (value) => setState(() => _privacyNoticeAcknowledged = value),
                        title: const Text('Privacy notice acknowledged'),
                      ),
                      SwitchListTile(
                        value: _recordingConsentObtained,
                        onChanged: _submitting
                            ? null
                            : (value) => setState(() => _recordingConsentObtained = value),
                        title: const Text('Recording consent captured'),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 320,
                        child: DropdownButtonFormField<String>(
                          initialValue: _recordingConsentMethod,
                          decoration: const InputDecoration(labelText: 'Recording consent method'),
                          items: const [
                            DropdownMenuItem(value: 'verbal', child: Text('Verbal')),
                            DropdownMenuItem(value: 'written', child: Text('Written')),
                            DropdownMenuItem(value: 'digital', child: Text('Digital')),
                          ],
                          onChanged: _submitting || !_recordingConsentObtained
                              ? null
                              : (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setState(() => _recordingConsentMethod = value);
                                },
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: _aiConsentObtained,
                        onChanged: _submitting
                            ? null
                            : (value) => setState(() => _aiConsentObtained = value),
                        title: const Text('AI transcription consent captured'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _consentNotesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Consent notes (optional)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _submitting ? null : _save,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow_outlined),
                    label: Text(_submitting ? 'Starting...' : 'Start encounter'),
                  ),
                  OutlinedButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).maybePop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTemplate() async {
    final result = await Navigator.of(context).pushNamed(
      AppRouter.templatePicker,
      arguments: TemplatePickerRouteArgs(
        selectedTemplateId: _selectedTemplate?.id,
      ),
    );

    if (!mounted || result is! EncounterTemplate) {
      return;
    }

    setState(() => _selectedTemplate = result);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if ((widget.patientId?.trim().isNotEmpty != true) && (widget.appointmentId?.trim().isNotEmpty != true)) {
      setState(() {
        _errorMessage = 'A patient or appointment context is required before starting an encounter.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final draft = EncounterDraft(
      patientId: widget.patientId,
      appointmentId: widget.appointmentId,
      providerId: _trim(_providerIdController.text),
      encounterTemplateId: _selectedTemplate?.id,
      encounterType: _encounterType,
      chiefComplaint: _trim(_chiefComplaintController.text),
      privacyNoticeAcknowledgedAt: _privacyNoticeAcknowledged ? DateTime.now() : null,
      recordingConsentObtainedAt: _recordingConsentObtained ? DateTime.now() : null,
      recordingConsentMethod: _recordingConsentObtained ? _recordingConsentMethod : null,
      aiTranscriptionConsentObtainedAt: _aiConsentObtained ? DateTime.now() : null,
      consentNotes: _trim(_consentNotesController.text),
      startedAt: DateTime.now(),
    );

    try {
      final encounter = await ref.read(encountersControllerProvider.notifier).startEncounter(draft);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacementNamed(
        AppRouter.encounterDetail,
        arguments: EncounterDetailRouteArgs(
          encounterId: encounter.id,
          patientName: widget.patientName ?? encounter.patient?.fullName,
        ),
      );
    } catch (error) {
      setState(() {
        _submitting = false;
        _errorMessage = error.toString();
      });
      return;
    }

    if (mounted) {
      setState(() => _submitting = false);
    }
  }

  String? _trim(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}