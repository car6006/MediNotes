import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../encounters/presentation/screens/encounter_list_screen.dart';
import '../../../encounters/presentation/screens/start_encounter_screen.dart';
import '../../../appointments/presentation/screens/appointment_form_screen.dart';
import '../../../appointments/presentation/screens/appointment_list_screen.dart';
import '../../../consents/presentation/screens/consent_capture_screen.dart';
import '../../../consents/presentation/screens/patient_consent_history_screen.dart';
import '../../../onboarding/presentation/screens/onboarding_form_screen.dart';
import '../../domain/entities/patient.dart';
import '../../domain/entities/patient_summary.dart';
import '../../domain/entities/patient_visit_timeline_item.dart';
import '../controllers/patients_controller.dart';
import '../widgets/patient_summary_card.dart';
import '../widgets/patient_visit_timeline.dart';
import 'patient_form_screen.dart';

class PatientDetailRouteArgs {
  const PatientDetailRouteArgs({required this.patientId});

  final String patientId;
}

class PatientDetailScreen extends ConsumerStatefulWidget {
  const PatientDetailScreen({super.key, required this.patientId});

  final String patientId;

  @override
  ConsumerState<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(patientsControllerProvider.notifier).selectPatient(widget.patientId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final patientsState = ref.watch(patientsControllerProvider);
    final current = patientsState.valueOrNull;
    final patient = current?.selectedPatient?.id == widget.patientId
        ? current?.selectedPatient
        : null;
    final summary = current?.selectedSummary;
    final timeline = current?.timeline ?? const <PatientVisitTimelineItem>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient detail'),
        actions: [
          if (patient != null)
            IconButton(
              tooltip: 'Edit patient',
              onPressed: () async {
                final result = await Navigator.of(context).pushNamed(
                  AppRouter.patientForm,
                  arguments: PatientFormRouteArgs(patient: patient),
                );

                if (!mounted || result is! String) {
                  return;
                }

                await ref.read(patientsControllerProvider.notifier).selectPatient(result);
              },
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: patientsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(error.toString(), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        data: (_) {
          if (patient == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('The requested patient could not be loaded.'),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: PatientDetailContent(
              patient: patient,
              summary: summary ?? PatientSummary.fromPatient(patient),
              timeline: timeline,
              isLoading: current?.isLoadingDetail ?? false,
            ),
          );
        },
      ),
    );
  }
}

class PatientDetailContent extends StatelessWidget {
  const PatientDetailContent({
    super.key,
    required this.patient,
    required this.summary,
    required this.timeline,
    this.isLoading = false,
  });

  final Patient patient;
  final PatientSummary summary;
  final List<PatientVisitTimelineItem> timeline;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(),
          ),
        PatientSummaryCard(summary: summary),
        const SizedBox(height: 16),
        _PatientWorkflowActions(patient: patient),
        const SizedBox(height: 16),
        _PatientDetailsCard(patient: patient),
        const SizedBox(height: 16),
        PatientVisitTimeline(timeline: timeline),
      ],
    );
  }
}

class _PatientWorkflowActions extends StatelessWidget {
  const _PatientWorkflowActions({required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clinical workflows',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRouter.encounterList,
                    arguments: EncounterListRouteArgs(
                      patientId: patient.id,
                      patientName: patient.displayName,
                    ),
                  ),
                  icon: const Icon(Icons.medical_information_outlined),
                  label: const Text('Encounters'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRouter.startEncounter,
                    arguments: StartEncounterRouteArgs(
                      patientId: patient.id,
                      patientName: patient.displayName,
                    ),
                  ),
                  icon: const Icon(Icons.playlist_add_check_circle_outlined),
                  label: const Text('Start encounter'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRouter.appointmentList,
                    arguments: AppointmentListRouteArgs(
                      patientId: patient.id,
                      patientName: patient.displayName,
                    ),
                  ),
                  icon: const Icon(Icons.event_note_outlined),
                  label: const Text('Appointments'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRouter.appointmentForm,
                    arguments: AppointmentFormRouteArgs(
                      patientId: patient.id,
                      patientName: patient.displayName,
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Book appointment'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRouter.onboardingForm,
                    arguments: OnboardingFormRouteArgs(
                      patientId: patient.id,
                      patientName: patient.displayName,
                    ),
                  ),
                  icon: const Icon(Icons.assignment_outlined),
                  label: const Text('Onboarding'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRouter.consentCapture,
                    arguments: ConsentCaptureRouteArgs(
                      patientId: patient.id,
                      patientName: patient.displayName,
                    ),
                  ),
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('Capture consent'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRouter.consentHistory,
                    arguments: PatientConsentHistoryRouteArgs(
                      patientId: patient.id,
                      patientName: patient.displayName,
                    ),
                  ),
                  icon: const Icon(Icons.history_outlined),
                  label: const Text('Consent history'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientDetailsCard extends StatelessWidget {
  const _PatientDetailsCard({required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registry details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _DetailColumn(
                  title: 'Identifiers',
                  values: {
                    'MRN': patient.medicalRecordNumber,
                    'National ID': patient.nationalIdNumber,
                    'Passport': patient.passportNumber,
                    'External ref': patient.externalReference,
                  },
                ),
                _DetailColumn(
                  title: 'Contact',
                  values: {
                    'Phone': patient.phone,
                    'Alternate': patient.alternatePhone,
                    'Email': patient.email,
                    'Emergency contact': patient.emergencyContactName,
                    'Emergency phone': patient.emergencyContactPhone,
                  },
                ),
                _DetailColumn(
                  title: 'Address',
                  values: {
                    'Address': patient.addressSummary,
                    'Clinic': patient.clinicName,
                  },
                ),
              ],
            ),
            if (patient.notes?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              Text(
                'Notes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(patient.notes!),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailColumn extends StatelessWidget {
  const _DetailColumn({required this.title, required this.values});

  final String title;
  final Map<String, String?> values;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...values.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 2),
                  Text(
                    entry.value?.trim().isNotEmpty == true ? entry.value! : '—',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
