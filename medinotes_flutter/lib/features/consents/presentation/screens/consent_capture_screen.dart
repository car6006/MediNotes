import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../domain/entities/consent_capture_draft.dart';
import '../controllers/consents_controller.dart';
import 'patient_consent_history_screen.dart';

class ConsentCaptureRouteArgs {
  const ConsentCaptureRouteArgs({
    required this.patientId,
    this.patientName,
    this.appointmentId,
  });

  final String patientId;
  final String? patientName;
  final String? appointmentId;
}

class ConsentCaptureScreen extends ConsumerStatefulWidget {
  const ConsentCaptureScreen({
    super.key,
    required this.patientId,
    this.patientName,
    this.appointmentId,
  });

  final String patientId;
  final String? patientName;
  final String? appointmentId;

  @override
  ConsumerState<ConsentCaptureScreen> createState() => _ConsentCaptureScreenState();
}

class _ConsentCaptureScreenState extends ConsumerState<ConsentCaptureScreen> {
  late final TextEditingController _acceptedByController;
  late final TextEditingController _notesController;
  String _sourceChannel = 'admin_capture';

  @override
  void initState() {
    super.initState();
    _acceptedByController = TextEditingController();
    _notesController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(consentsControllerProvider.notifier).load(
        widget.patientId,
        appointmentId: widget.appointmentId,
      );
    });
  }

  @override
  void dispose() {
    _acceptedByController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final consentsState = ref.watch(consentsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.patientName?.trim().isNotEmpty == true
              ? 'Consent · ${widget.patientName}'
              : 'Consent capture',
        ),
      ),
      body: consentsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.read(consentsControllerProvider.notifier).load(
                widget.patientId,
                appointmentId: widget.appointmentId,
              ),
        ),
        data: (state) {
          final template = state.selectedTemplate;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.templates.isNotEmpty)
                  DropdownButton<String>(
                    value: template?.id,
                    items: state.templates
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item.id,
                            child: Text('${item.title} · v${item.version}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => ref.read(consentsControllerProvider.notifier).selectTemplate(value),
                  ),
                if (state.message?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 12),
                  Text(state.message!),
                ],
                const SizedBox(height: 20),
                if (template == null)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No consent template is currently available.'),
                    ),
                  )
                else ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(template.title, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text('Type: ${template.consentType} · Version: ${template.version}'),
                          if (template.description?.trim().isNotEmpty ?? false) ...[
                            const SizedBox(height: 8),
                            Text(template.description!),
                          ],
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(template.body),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _acceptedByController,
                            decoration: const InputDecoration(
                              labelText: 'Accepted by',
                              hintText: 'Patient or authorised representative name',
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: ValueKey(_sourceChannel),
                            initialValue: _sourceChannel,
                            decoration: const InputDecoration(labelText: 'Capture source'),
                            items: const [
                              DropdownMenuItem(value: 'admin_capture', child: Text('Admin capture')),
                              DropdownMenuItem(value: 'in_person', child: Text('In person')),
                              DropdownMenuItem(value: 'mobile', child: Text('Mobile')),
                              DropdownMenuItem(value: 'web', child: Text('Web')),
                            ],
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() => _sourceChannel = value);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(labelText: 'Notes'),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: state.isSubmitting ? null : () => _capture(template.id),
                            icon: state.isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.verified_user_outlined),
                            label: Text(state.isSubmitting ? 'Capturing...' : 'Capture consent'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.tonalIcon(
                    onPressed: () => Navigator.of(context).pushNamed(
                      AppRouter.consentHistory,
                      arguments: PatientConsentHistoryRouteArgs(
                        patientId: widget.patientId,
                        patientName: widget.patientName,
                      ),
                    ),
                    icon: const Icon(Icons.history_outlined),
                    label: const Text('View consent history'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _capture(String templateId) async {
    final acceptedBy = _acceptedByController.text.trim();
    if (acceptedBy.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Accepted by is required.')),
      );
      return;
    }

    try {
      await ref.read(consentsControllerProvider.notifier).capture(
            ConsentCaptureDraft(
              patientId: widget.patientId,
              appointmentId: widget.appointmentId,
              consentTemplateId: templateId,
              acceptedBy: acceptedBy,
              sourceChannel: _sourceChannel,
              acceptedPayload: const {'captured_in_phase': 'phase_3'},
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            ),
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consent captured.')),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
