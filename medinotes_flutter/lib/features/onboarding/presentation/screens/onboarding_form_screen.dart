import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/onboarding_form.dart';
import '../../domain/entities/onboarding_submission.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingFormRouteArgs {
  const OnboardingFormRouteArgs({
    required this.patientId,
    this.patientName,
    this.appointmentId,
  });

  final String patientId;
  final String? patientName;
  final String? appointmentId;
}

class OnboardingFormScreen extends ConsumerStatefulWidget {
  const OnboardingFormScreen({
    super.key,
    required this.patientId,
    this.patientName,
    this.appointmentId,
  });

  final String patientId;
  final String? patientName;
  final String? appointmentId;

  @override
  ConsumerState<OnboardingFormScreen> createState() => _OnboardingFormScreenState();
}

class _OnboardingFormScreenState extends ConsumerState<OnboardingFormScreen> {
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, bool> _booleanValues = {};
  final Map<String, String> _selectedOptions = {};
  final Map<String, DateTime> _selectedDates = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingControllerProvider.notifier).load(
        widget.patientId,
        appointmentId: widget.appointmentId,
      );
    });
  }

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.patientName?.trim().isNotEmpty == true
              ? 'Onboarding · ${widget.patientName}'
              : 'Patient onboarding',
        ),
      ),
      body: onboardingState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.read(onboardingControllerProvider.notifier).load(
                widget.patientId,
                appointmentId: widget.appointmentId,
              ),
        ),
        data: (state) {
          final selectedForm = state.selectedForm;
          if (selectedForm != null) {
            _ensureFieldsInitialized(selectedForm);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.forms.isNotEmpty)
                  DropdownButton<String>(
                    value: selectedForm?.id,
                    items: state.forms
                        .map(
                          (form) => DropdownMenuItem<String>(
                            value: form.id,
                            child: Text('${form.title} · v${form.version}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        ref.read(onboardingControllerProvider.notifier).selectForm(value),
                  ),
                if (state.message?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 12),
                  Text(state.message!),
                ],
                const SizedBox(height: 20),
                if (selectedForm == null)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No onboarding form is currently available.'),
                    ),
                  )
                else ...[
                  _FormCard(
                    form: selectedForm,
                    buildField: _buildField,
                    onSubmit: state.isSubmitting ? null : () => _submit(selectedForm),
                    isSubmitting: state.isSubmitting,
                  ),
                  const SizedBox(height: 20),
                  _HistoryCard(responses: state.responses),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _ensureFieldsInitialized(OnboardingForm form) {
    for (final field in form.fields) {
      switch (field.type) {
        case 'boolean':
          _booleanValues.putIfAbsent(field.key, () => false);
          break;
        case 'select':
          if (field.options.isNotEmpty) {
            _selectedOptions.putIfAbsent(field.key, () => field.options.first);
          }
          break;
        case 'date':
          break;
        default:
          _textControllers.putIfAbsent(field.key, () => TextEditingController());
      }
    }
  }

  Widget _buildField(OnboardingFormField field) {
    switch (field.type) {
      case 'boolean':
        return SwitchListTile(
          value: _booleanValues[field.key] ?? false,
          title: Text(field.label),
          subtitle: field.helperText == null ? null : Text(field.helperText!),
          onChanged: (value) {
            setState(() => _booleanValues[field.key] = value);
          },
        );
      case 'select':
        final options = field.options;
        final selected = _selectedOptions[field.key];
        return DropdownButtonFormField<String>(
          key: ValueKey('${field.key}:${selected ?? ''}'),
          initialValue: selected,
          decoration: InputDecoration(labelText: field.label),
          items: options
              .map((option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  ))
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() => _selectedOptions[field.key] = value);
          },
        );
      case 'date':
        final date = _selectedDates[field.key];
        return OutlinedButton(
          onPressed: () => _pickDate(field.key),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${field.label}: ${date == null ? 'Select date' : DateFormat('dd MMM yyyy').format(date)}',
              ),
            ),
          ),
        );
      case 'textarea':
        return TextField(
          controller: _textControllers[field.key],
          maxLines: 4,
          decoration: InputDecoration(
            labelText: field.label,
            helperText: field.helperText,
            hintText: field.placeholder,
          ),
        );
      default:
        return TextField(
          controller: _textControllers[field.key],
          decoration: InputDecoration(
            labelText: field.label,
            helperText: field.helperText,
            hintText: field.placeholder,
          ),
        );
    }
  }

  Future<void> _pickDate(String key) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDates[key] ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked == null) {
      return;
    }

    setState(() => _selectedDates[key] = picked);
  }

  Future<void> _submit(OnboardingForm form) async {
    final responses = <String, dynamic>{};

    for (final field in form.fields) {
      switch (field.type) {
        case 'boolean':
          responses[field.key] = _booleanValues[field.key] ?? false;
          break;
        case 'select':
          responses[field.key] = _selectedOptions[field.key];
          break;
        case 'date':
          responses[field.key] = _selectedDates[field.key]?.toIso8601String();
          break;
        default:
          responses[field.key] = _textControllers[field.key]?.text.trim();
      }
    }

    final missingRequired = form.fields.where((field) {
      if (!field.required) {
        return false;
      }

      final value = responses[field.key];
      if (value is bool) {
        return false;
      }

      return value == null || value.toString().trim().isEmpty;
    }).toList();

    if (missingRequired.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Complete required fields: ${missingRequired.map((field) => field.label).join(', ')}',
          ),
        ),
      );
      return;
    }

    try {
      await ref.read(onboardingControllerProvider.notifier).submit(
            OnboardingSubmission(
              patientId: widget.patientId,
              appointmentId: widget.appointmentId,
              onboardingFormId: form.id,
              responses: responses,
            ),
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Onboarding submitted.')),
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

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.form,
    required this.buildField,
    required this.isSubmitting,
    this.onSubmit,
  });

  final OnboardingForm form;
  final Widget Function(OnboardingFormField field) buildField;
  final bool isSubmitting;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(form.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (form.description?.trim().isNotEmpty ?? false) Text(form.description!),
            const SizedBox(height: 16),
            ...form.fields.map(
              (field) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: buildField(field),
              ),
            ),
            FilledButton.icon(
              onPressed: onSubmit,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.assignment_turned_in_outlined),
              label: Text(isSubmitting ? 'Submitting...' : 'Submit onboarding'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.responses});

  final List<dynamic> responses;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Previous onboarding', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (responses.isEmpty)
              const Text('No onboarding responses have been submitted yet.')
            else
              ...responses.map(
                (response) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(response.formTitle),
                  subtitle: Text(
                    DateFormat('dd MMM yyyy · HH:mm').format(response.submittedAt.toLocal()),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
