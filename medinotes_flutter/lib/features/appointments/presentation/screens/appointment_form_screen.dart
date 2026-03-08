import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../patients/domain/entities/patient_draft.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/appointment_draft.dart';
import '../controllers/appointments_controller.dart';

class AppointmentFormRouteArgs {
  const AppointmentFormRouteArgs({
    this.appointment,
    this.patientId,
    this.patientName,
  });

  final Appointment? appointment;
  final String? patientId;
  final String? patientName;
}

class AppointmentFormScreen extends ConsumerStatefulWidget {
  const AppointmentFormScreen({
    super.key,
    this.appointment,
    this.patientId,
    this.patientName,
  });

  final Appointment? appointment;
  final String? patientId;
  final String? patientName;

  @override
  ConsumerState<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends ConsumerState<AppointmentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _patientIdController;
  late final TextEditingController _reasonController;
  late final TextEditingController _notesController;
  late final TextEditingController _durationController;
  late final TextEditingController _providerIdController;
  late final TextEditingController _cancellationReasonController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String _bookingType = 'returning_patient';
  String _status = 'booked';
  bool _submitting = false;
  String? _errorMessage;

  bool get _editing => widget.appointment != null;

  @override
  void initState() {
    super.initState();
    final appointment = widget.appointment;
    final scheduled = appointment?.scheduledFor ?? DateTime.now().add(const Duration(hours: 1));
    _selectedDate = DateTime(scheduled.year, scheduled.month, scheduled.day);
    _selectedTime = TimeOfDay(hour: scheduled.hour, minute: scheduled.minute);
    _bookingType = appointment?.bookingType ?? (widget.patientId == null ? 'new_patient' : 'returning_patient');
    _status = appointment?.status ?? 'booked';
    _patientIdController = TextEditingController(text: widget.patientId ?? appointment?.patientId ?? '');
    _reasonController = TextEditingController(text: appointment?.reasonForVisit ?? '');
    _notesController = TextEditingController(text: appointment?.notes ?? '');
    _durationController = TextEditingController(text: '${appointment?.durationMinutes ?? 30}');
    _providerIdController = TextEditingController(text: appointment?.providerId ?? '');
    _cancellationReasonController = TextEditingController(text: appointment?.cancellationReason ?? '');
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    for (final controller in [
      _patientIdController,
      _reasonController,
      _notesController,
      _durationController,
      _providerIdController,
      _cancellationReasonController,
      _firstNameController,
      _lastNameController,
      _phoneController,
      _emailController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit appointment' : 'Book appointment'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.patientName?.trim().isNotEmpty == true
                    ? 'Booking for ${widget.patientName}'
                    : 'Capture new or returning patient bookings.',
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
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  DropdownButton<String>(
                    value: _bookingType,
                    items: const [
                      DropdownMenuItem(
                        value: 'returning_patient',
                        child: Text('Returning patient'),
                      ),
                      DropdownMenuItem(
                        value: 'new_patient',
                        child: Text('New patient'),
                      ),
                    ],
                    onChanged: _submitting
                        ? null
                        : (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() => _bookingType = value);
                          },
                  ),
                  DropdownButton<String>(
                    value: _status,
                    items: const [
                      DropdownMenuItem(value: 'booked', child: Text('Booked')),
                      DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                      DropdownMenuItem(value: 'arrived', child: Text('Arrived')),
                      DropdownMenuItem(value: 'in_consult', child: Text('In consult')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                      DropdownMenuItem(value: 'no_show', child: Text('No show')),
                    ],
                    onChanged: _submitting
                        ? null
                        : (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() => _status = value);
                          },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _Section(
                title: 'Scheduling',
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _ActionField(
                      label: 'Appointment date',
                      value: '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                      onTap: _submitting ? null : _pickDate,
                    ),
                    _ActionField(
                      label: 'Appointment time',
                      value: _selectedTime.format(context),
                      onTap: _submitting ? null : _pickTime,
                    ),
                    _field(
                      _durationController,
                      'Duration (minutes)',
                      keyboardType: TextInputType.number,
                      validator: _requiredValidator,
                    ),
                    _field(_providerIdController, 'Provider ID (optional)'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_bookingType == 'returning_patient')
                _Section(
                  title: 'Returning patient',
                  child: _field(
                    _patientIdController,
                    'Patient ID',
                    validator: _requiredValidator,
                    readOnly: widget.patientId?.trim().isNotEmpty == true,
                  ),
                )
              else
                _Section(
                  title: 'New patient booking',
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _field(
                        _firstNameController,
                        'First name',
                        validator: _requiredValidator,
                      ),
                      _field(
                        _lastNameController,
                        'Last name',
                        validator: _requiredValidator,
                      ),
                      _field(_phoneController, 'Phone'),
                      _field(_emailController, 'Email'),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              _Section(
                title: 'Consult context',
                child: Column(
                  children: [
                    _fullField(_reasonController, 'Reason for visit'),
                    const SizedBox(height: 12),
                    _fullField(_notesController, 'Scheduling notes', maxLines: 4),
                    if (_status == 'cancelled') ...[
                      const SizedBox(height: 12),
                      _fullField(
                        _cancellationReasonController,
                        'Cancellation reason',
                        maxLines: 3,
                      ),
                    ],
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
                    label: Text(_submitting ? 'Saving...' : 'Save appointment'),
                  ),
                  const SizedBox(width: 12),
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked == null) {
      return;
    }

    setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked == null) {
      return;
    }

    setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final scheduledFor = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final newPatient = _bookingType == 'new_patient'
        ? PatientDraft(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            phone: _trim(_phoneController.text),
            email: _trim(_emailController.text),
          )
        : null;

    final draft = AppointmentDraft(
      bookingType: _bookingType,
      patientId: _bookingType == 'returning_patient'
          ? _patientIdController.text.trim()
          : null,
      newPatient: newPatient,
      providerId: _trim(_providerIdController.text),
      status: _status,
      scheduledFor: scheduledFor,
      durationMinutes: int.tryParse(_durationController.text.trim()) ?? 30,
      reasonForVisit: _trim(_reasonController.text),
      notes: _trim(_notesController.text),
      cancellationReason: _trim(_cancellationReasonController.text),
    );

    try {
      final notifier = ref.read(appointmentsControllerProvider.notifier);
      if (_editing) {
        await notifier.updateAppointment(widget.appointment!.id, draft);
      } else {
        await notifier.createAppointment(draft);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
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

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }

    return null;
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

class _ActionField extends StatelessWidget {
  const _ActionField({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: OutlinedButton(
        onPressed: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 6),
              Text(value),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _field(
  TextEditingController controller,
  String label, {
  String? Function(String? value)? validator,
  TextInputType? keyboardType,
  bool readOnly = false,
}) {
  return SizedBox(
    width: 280,
    child: TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(labelText: label),
    ),
  );
}

Widget _fullField(
  TextEditingController controller,
  String label, {
  int maxLines = 2,
}) {
  return TextFormField(
    controller: controller,
    maxLines: maxLines,
    decoration: InputDecoration(labelText: label),
  );
}
