import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/router.dart';
import '../../../consents/presentation/screens/consent_capture_screen.dart';
import '../../../encounters/presentation/screens/encounter_list_screen.dart';
import '../../../encounters/presentation/screens/start_encounter_screen.dart';
import '../../../onboarding/presentation/screens/onboarding_form_screen.dart';
import '../../domain/entities/appointment.dart';
import '../controllers/appointments_controller.dart';
import 'appointment_form_screen.dart';

class AppointmentListRouteArgs {
  const AppointmentListRouteArgs({this.patientId, this.patientName});

  final String? patientId;
  final String? patientName;
}

class AppointmentListScreen extends ConsumerStatefulWidget {
  const AppointmentListScreen({super.key, this.patientId, this.patientName});

  final String? patientId;
  final String? patientName;

  @override
  ConsumerState<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends ConsumerState<AppointmentListScreen> {
  static const _statuses = <String?>[
    null,
    'booked',
    'confirmed',
    'arrived',
    'in_consult',
    'completed',
    'cancelled',
    'no_show',
  ];

  String? _statusFilter;
  DateTime? _dateFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(appointmentsControllerProvider.notifier)
          .load(patientId: widget.patientId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsState = ref.watch(appointmentsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patientId == null
            ? 'Appointments'
            : 'Appointments · ${widget.patientName ?? 'Patient'}'),
        actions: [
          IconButton(
            tooltip: 'Refresh appointments',
            onPressed: () => ref.read(appointmentsControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateAppointment(),
        icon: const Icon(Icons.event_available_outlined),
        label: const Text('Book'),
      ),
      body: appointmentsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.read(appointmentsControllerProvider.notifier).refresh(),
        ),
        data: (state) => Column(
          children: [
            _FiltersCard(
              statusFilter: _statusFilter,
              dateFilter: _dateFilter,
              statuses: _statuses,
              onStatusChanged: (value) {
                setState(() => _statusFilter = value);
                ref.read(appointmentsControllerProvider.notifier).load(
                  patientId: widget.patientId,
                  status: value,
                  date: _dateFilter,
                );
              },
              onDateTap: _pickDate,
              onClearDate: () {
                setState(() => _dateFilter = null);
                ref.read(appointmentsControllerProvider.notifier).load(
                  patientId: widget.patientId,
                  status: _statusFilter,
                  date: null,
                );
              },
              message: state.message,
            ),
            Expanded(
              child: state.appointments.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No appointments matched the current filters.'),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.appointments.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final appointment = state.appointments[index];
                        return _AppointmentCard(
                          appointment: appointment,
                          onEdit: () => _openEditAppointment(appointment),
                          onOpenEncounters: () => Navigator.of(context).pushNamed(
                            AppRouter.encounterList,
                            arguments: EncounterListRouteArgs(
                              patientId: appointment.patientId,
                              patientName: appointment.patientDisplayName,
                              appointmentId: appointment.id,
                            ),
                          ),
                          onStartEncounter: () => Navigator.of(context).pushNamed(
                            AppRouter.startEncounter,
                            arguments: StartEncounterRouteArgs(
                              patientId: appointment.patientId,
                              patientName: appointment.patientDisplayName,
                              appointmentId: appointment.id,
                              initialChiefComplaint: appointment.reasonForVisit,
                            ),
                          ),
                          onOpenOnboarding: widget.patientId == null
                              ? null
                              : () => Navigator.of(context).pushNamed(
                                    AppRouter.onboardingForm,
                                    arguments: OnboardingFormRouteArgs(
                                      patientId: widget.patientId!,
                                      patientName: widget.patientName,
                                      appointmentId: appointment.id,
                                    ),
                                  ),
                          onOpenConsent: widget.patientId == null
                              ? null
                              : () => Navigator.of(context).pushNamed(
                                    AppRouter.consentCapture,
                                    arguments: ConsentCaptureRouteArgs(
                                      patientId: widget.patientId!,
                                      patientName: widget.patientName,
                                      appointmentId: appointment.id,
                                    ),
                                  ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFilter ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked == null) {
      return;
    }

    setState(() => _dateFilter = picked);
    await ref.read(appointmentsControllerProvider.notifier).load(
      patientId: widget.patientId,
      status: _statusFilter,
      date: picked,
    );
  }

  Future<void> _openCreateAppointment() async {
    await Navigator.of(context).pushNamed(
      AppRouter.appointmentForm,
      arguments: AppointmentFormRouteArgs(
        patientId: widget.patientId,
        patientName: widget.patientName,
      ),
    );
  }

  Future<void> _openEditAppointment(Appointment appointment) async {
    await Navigator.of(context).pushNamed(
      AppRouter.appointmentForm,
      arguments: AppointmentFormRouteArgs(
        appointment: appointment,
        patientId: widget.patientId,
        patientName: widget.patientName,
      ),
    );
  }
}

class _FiltersCard extends StatelessWidget {
  const _FiltersCard({
    required this.statusFilter,
    required this.dateFilter,
    required this.statuses,
    required this.onStatusChanged,
    required this.onDateTap,
    required this.onClearDate,
    this.message,
  });

  final String? statusFilter;
  final DateTime? dateFilter;
  final List<String?> statuses;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onDateTap;
  final VoidCallback onClearDate;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<String?>(
                  value: statusFilter,
                  hint: const Text('Any status'),
                  items: statuses
                      .map(
                        (status) => DropdownMenuItem<String?>(
                          value: status,
                          child: Text(status == null ? 'Any status' : _title(status)),
                        ),
                      )
                      .toList(),
                  onChanged: onStatusChanged,
                ),
                OutlinedButton.icon(
                  onPressed: onDateTap,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    dateFilter == null
                        ? 'Filter by date'
                        : DateFormat('dd MMM yyyy').format(dateFilter!),
                  ),
                ),
                if (dateFilter != null)
                  TextButton.icon(
                    onPressed: onClearDate,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear date'),
                  ),
              ],
            ),
            if (message?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Text(message!),
            ],
          ],
        ),
      ),
    );
  }

  String _title(String value) {
    return value.split('_').map((part) {
      if (part.isEmpty) {
        return part;
      }
      return part[0].toUpperCase() + part.substring(1);
    }).join(' ');
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.onEdit,
    required this.onOpenEncounters,
    required this.onStartEncounter,
    this.onOpenOnboarding,
    this.onOpenConsent,
  });

  final Appointment appointment;
  final VoidCallback onEdit;
  final VoidCallback onOpenEncounters;
  final VoidCallback onStartEncounter;
  final VoidCallback? onOpenOnboarding;
  final VoidCallback? onOpenConsent;

  @override
  Widget build(BuildContext context) {
    final scheduledLabel = DateFormat('EEE, dd MMM yyyy · HH:mm').format(
      appointment.scheduledFor.toLocal(),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        appointment.patientDisplayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(scheduledLabel),
                    ],
                  ),
                ),
                Chip(label: Text(_statusTitle(appointment.status))),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _MetaChip(
                  icon: Icons.local_hospital_outlined,
                  label: appointment.reasonForVisit?.trim().isNotEmpty == true
                      ? appointment.reasonForVisit!
                      : 'Consult booking',
                ),
                _MetaChip(
                  icon: Icons.schedule_outlined,
                  label: '${appointment.durationMinutes} min',
                ),
                if (appointment.providerName?.trim().isNotEmpty ?? false)
                  _MetaChip(
                    icon: Icons.badge_outlined,
                    label: appointment.providerName!,
                  ),
              ],
            ),
            if (appointment.notes?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Text(appointment.notes!),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_calendar_outlined),
                  label: const Text('Edit'),
                ),
                OutlinedButton.icon(
                  onPressed: onStartEncounter,
                  icon: const Icon(Icons.playlist_add_check_circle_outlined),
                  label: const Text('Start encounter'),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenEncounters,
                  icon: const Icon(Icons.medical_information_outlined),
                  label: const Text('Encounters'),
                ),
                if (onOpenOnboarding != null)
                  OutlinedButton.icon(
                    onPressed: onOpenOnboarding,
                    icon: const Icon(Icons.assignment_outlined),
                    label: const Text('Onboarding'),
                  ),
                if (onOpenConsent != null)
                  OutlinedButton.icon(
                    onPressed: onOpenConsent,
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('Consent'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusTitle(String value) {
    return value.split('_').map((part) {
      if (part.isEmpty) {
        return part;
      }
      return part[0].toUpperCase() + part.substring(1);
    }).join(' ');
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

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
