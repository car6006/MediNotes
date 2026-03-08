import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/patient.dart';
import '../../domain/entities/patient_draft.dart';
import '../controllers/patients_controller.dart';

class PatientFormRouteArgs {
  const PatientFormRouteArgs({this.patient});

  final Patient? patient;
}

class PatientFormScreen extends ConsumerStatefulWidget {
  const PatientFormScreen({super.key, this.patient});

  final Patient? patient;

  @override
  ConsumerState<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends ConsumerState<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _medicalRecordController;
  late final TextEditingController _titleController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _middleNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _preferredNameController;
  late final TextEditingController _sexController;
  late final TextEditingController _phoneController;
  late final TextEditingController _alternatePhoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _nationalIdController;
  late final TextEditingController _passportController;
  late final TextEditingController _externalReferenceController;
  late final TextEditingController _addressLine1Controller;
  late final TextEditingController _addressLine2Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _provinceController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _countryController;
  late final TextEditingController _emergencyContactNameController;
  late final TextEditingController _emergencyContactPhoneController;
  late final TextEditingController _allergiesController;
  late final TextEditingController _allergiesSummaryController;
  late final TextEditingController _medicationsController;
  late final TextEditingController _medicationSummaryController;
  late final TextEditingController _medicalHistoryController;
  late final TextEditingController _medicalHistorySummaryController;
  late final TextEditingController _alertsController;
  late final TextEditingController _notesController;

  DateTime? _dateOfBirth;
  bool _submitting = false;
  String? _errorMessage;

  bool get _editing => widget.patient != null;

  @override
  void initState() {
    super.initState();
    final patient = widget.patient;
    _medicalRecordController = TextEditingController(
      text: patient?.medicalRecordNumber ?? '',
    );
    _titleController = TextEditingController(text: patient?.title ?? '');
    _firstNameController = TextEditingController(text: patient?.firstName ?? '');
    _middleNameController = TextEditingController(text: patient?.middleName ?? '');
    _lastNameController = TextEditingController(text: patient?.lastName ?? '');
    _preferredNameController = TextEditingController(
      text: patient?.preferredName ?? '',
    );
    _sexController = TextEditingController(text: patient?.sex ?? '');
    _phoneController = TextEditingController(text: patient?.phone ?? '');
    _alternatePhoneController = TextEditingController(
      text: patient?.alternatePhone ?? '',
    );
    _emailController = TextEditingController(text: patient?.email ?? '');
    _nationalIdController = TextEditingController(
      text: patient?.nationalIdNumber ?? '',
    );
    _passportController = TextEditingController(
      text: patient?.passportNumber ?? '',
    );
    _externalReferenceController = TextEditingController(
      text: patient?.externalReference ?? '',
    );
    _addressLine1Controller = TextEditingController(
      text: patient?.addressLine1 ?? '',
    );
    _addressLine2Controller = TextEditingController(
      text: patient?.addressLine2 ?? '',
    );
    _cityController = TextEditingController(text: patient?.city ?? '');
    _provinceController = TextEditingController(text: patient?.province ?? '');
    _postalCodeController = TextEditingController(
      text: patient?.postalCode ?? '',
    );
    _countryController = TextEditingController(text: patient?.country ?? 'ZA');
    _emergencyContactNameController = TextEditingController(
      text: patient?.emergencyContactName ?? '',
    );
    _emergencyContactPhoneController = TextEditingController(
      text: patient?.emergencyContactPhone ?? '',
    );
    _allergiesController = TextEditingController(
      text: patient == null ? '' : patient.allergies.join(', '),
    );
    _allergiesSummaryController = TextEditingController(
      text: patient?.allergiesSummary ?? '',
    );
    _medicationsController = TextEditingController(
      text: patient == null ? '' : patient.medications.join(', '),
    );
    _medicationSummaryController = TextEditingController(
      text: patient?.medicationSummary ?? '',
    );
    _medicalHistoryController = TextEditingController(
      text: patient == null ? '' : patient.medicalHistory.join(', '),
    );
    _medicalHistorySummaryController = TextEditingController(
      text: patient?.medicalHistorySummary ?? '',
    );
    _alertsController = TextEditingController(
      text: patient == null ? '' : patient.alerts.join(', '),
    );
    _notesController = TextEditingController(text: patient?.notes ?? '');
    _dateOfBirth = patient?.dateOfBirth;
  }

  @override
  void dispose() {
    for (final controller in [
      _medicalRecordController,
      _titleController,
      _firstNameController,
      _middleNameController,
      _lastNameController,
      _preferredNameController,
      _sexController,
      _phoneController,
      _alternatePhoneController,
      _emailController,
      _nationalIdController,
      _passportController,
      _externalReferenceController,
      _addressLine1Controller,
      _addressLine2Controller,
      _cityController,
      _provinceController,
      _postalCodeController,
      _countryController,
      _emergencyContactNameController,
      _emergencyContactPhoneController,
      _allergiesController,
      _allergiesSummaryController,
      _medicationsController,
      _medicationSummaryController,
      _medicalHistoryController,
      _medicalHistorySummaryController,
      _alertsController,
      _notesController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit patient' : 'New patient'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _editing
                    ? 'Update the patient registry entry.'
                    : 'Capture a new patient registry record.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
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
              _Section(
                title: 'Identity',
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _field(_medicalRecordController, 'Medical record number'),
                    _field(_titleController, 'Title'),
                    _field(
                      _firstNameController,
                      'First name',
                      validator: _requiredValidator,
                    ),
                    _field(_middleNameController, 'Middle name'),
                    _field(
                      _lastNameController,
                      'Last name',
                      validator: _requiredValidator,
                    ),
                    _field(_preferredNameController, 'Preferred name'),
                    _DateField(
                      label: 'Date of birth',
                      value: _dateOfBirth,
                      onTap: _pickDateOfBirth,
                    ),
                    _field(_sexController, 'Sex'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Section(
                title: 'Contact',
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _field(_phoneController, 'Phone'),
                    _field(_alternatePhoneController, 'Alternate phone'),
                    _field(_emailController, 'Email address'),
                    _field(_addressLine1Controller, 'Address line 1'),
                    _field(_addressLine2Controller, 'Address line 2'),
                    _field(_cityController, 'City'),
                    _field(_provinceController, 'Province'),
                    _field(_postalCodeController, 'Postal code'),
                    _field(_countryController, 'Country code'),
                    _field(
                      _emergencyContactNameController,
                      'Emergency contact name',
                    ),
                    _field(
                      _emergencyContactPhoneController,
                      'Emergency contact phone',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Section(
                title: 'Identifiers',
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _field(_nationalIdController, 'National ID'),
                    _field(_passportController, 'Passport number'),
                    _field(_externalReferenceController, 'External reference'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Section(
                title: 'Clinical placeholders',
                child: Column(
                  children: [
                    _fullField(
                      _medicalHistoryController,
                      'Medical history items (comma separated)',
                    ),
                    const SizedBox(height: 12),
                    _fullField(
                      _medicalHistorySummaryController,
                      'Medical history summary',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    _fullField(
                      _allergiesController,
                      'Allergies (comma separated)',
                    ),
                    const SizedBox(height: 12),
                    _fullField(
                      _allergiesSummaryController,
                      'Allergy summary',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    _fullField(
                      _medicationsController,
                      'Medications (comma separated)',
                    ),
                    const SizedBox(height: 12),
                    _fullField(
                      _medicationSummaryController,
                      'Medication summary',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    _fullField(
                      _alertsController,
                      'Alerts / flags (comma separated)',
                    ),
                    const SizedBox(height: 12),
                    _fullField(_notesController, 'Notes', maxLines: 4),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _submitting ? null : _save,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_submitting ? 'Saving...' : 'Save patient'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).maybePop(),
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

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime.now(),
    );

    if (picked == null) {
      return;
    }

    setState(() => _dateOfBirth = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final draft = PatientDraft(
      medicalRecordNumber: _trim(_medicalRecordController.text),
      title: _trim(_titleController.text),
      firstName: _firstNameController.text.trim(),
      middleName: _trim(_middleNameController.text),
      lastName: _lastNameController.text.trim(),
      preferredName: _trim(_preferredNameController.text),
      dateOfBirth: _dateOfBirth,
      sex: _trim(_sexController.text),
      phone: _trim(_phoneController.text),
      alternatePhone: _trim(_alternatePhoneController.text),
      email: _trim(_emailController.text),
      nationalIdNumber: _trim(_nationalIdController.text),
      passportNumber: _trim(_passportController.text),
      externalReference: _trim(_externalReferenceController.text),
      addressLine1: _trim(_addressLine1Controller.text),
      addressLine2: _trim(_addressLine2Controller.text),
      city: _trim(_cityController.text),
      province: _trim(_provinceController.text),
      postalCode: _trim(_postalCodeController.text),
      country: _trim(_countryController.text),
      emergencyContactName: _trim(_emergencyContactNameController.text),
      emergencyContactPhone: _trim(_emergencyContactPhoneController.text),
      allergies: _splitList(_allergiesController.text),
      allergiesSummary: _trim(_allergiesSummaryController.text),
      medications: _splitList(_medicationsController.text),
      medicationSummary: _trim(_medicationSummaryController.text),
      medicalHistory: _splitList(_medicalHistoryController.text),
      medicalHistorySummary: _trim(_medicalHistorySummaryController.text),
      alerts: _splitList(_alertsController.text),
      notes: _trim(_notesController.text),
    );

    try {
      final notifier = ref.read(patientsControllerProvider.notifier);
      final patientId = _editing
          ? await notifier.updatePatient(widget.patient!.id, draft)
          : await notifier.createPatient(draft);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(patientId);
    } catch (error) {
      if (!mounted) {
        return;
      }

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

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }

    return null;
  }

  String? _trim(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  List<String> _splitList(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      width: 280,
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _fullField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: Text(
            value == null ? 'Select date' : DateFormat('dd MMM yyyy').format(value!),
          ),
        ),
      ),
    );
  }
}
