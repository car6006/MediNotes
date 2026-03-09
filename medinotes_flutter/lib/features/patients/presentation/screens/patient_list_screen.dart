import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/router.dart';
import '../../../encounters/presentation/screens/encounter_list_screen.dart';
import '../../../appointments/presentation/screens/appointment_list_screen.dart';
import '../../domain/entities/patient.dart';
import '../../domain/entities/patient_summary.dart';
import '../../domain/entities/patient_visit_timeline_item.dart';
import '../controllers/patients_controller.dart';
import 'patient_detail_screen.dart';
import 'patient_form_screen.dart';

class PatientListScreen extends StatelessWidget {
  const PatientListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _PatientListAppBar(),
      body: SafeArea(
        child: PatientRegistryPanel(
          standalone: true,
          padding: EdgeInsets.all(24),
        ),
      ),
    );
  }
}

class PatientRegistryPanel extends ConsumerStatefulWidget {
  const PatientRegistryPanel({
    super.key,
    this.standalone = false,
    this.padding = const EdgeInsets.all(0),
  });

  final bool standalone;
  final EdgeInsets padding;

  @override
  ConsumerState<PatientRegistryPanel> createState() =>
      _PatientRegistryPanelState();
}

class _PatientRegistryPanelState extends ConsumerState<PatientRegistryPanel> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientsState = ref.watch(patientsControllerProvider);
    final current = patientsState.valueOrNull;

    if (_searchController.text != (current?.query ?? '')) {
      _searchController.value = TextEditingValue(
        text: current?.query ?? '',
        selection: TextSelection.collapsed(
          offset: (current?.query ?? '').length,
        ),
      );
    }

    return patientsState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _ErrorState(
        message: error.toString(),
        onRetry: () => ref.read(patientsControllerProvider.notifier).refresh(),
      ),
      data: (state) => Padding(
        padding: widget.padding,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wideLayout = constraints.maxWidth >= 1160;
            final contentHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight - (widget.standalone ? 140 : 120)
                : 760.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.standalone) ...[
                  Text(
                    'Patients',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lookup patients, review registry summaries, and capture new patient records without adding new workflow logic to the shell.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                ],
                _PatientToolbar(
                  searchController: _searchController,
                  message: state.message,
                  isSaving: state.isSaving,
                  onSearch: _submitSearch,
                  onClear: () async {
                    _searchController.clear();
                    await _submitSearch('');
                  },
                  onRefresh: () =>
                      ref.read(patientsControllerProvider.notifier).refresh(),
                  onCreatePatient: _openNewPatient,
                  onOpenAppointments: _openAppointments,
                  onOpenEncounters: _openEncounters,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: contentHeight < 360 ? 360 : contentHeight,
                  child: wideLayout
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _PatientListCard(
                                patients: state.patients,
                                selectedPatientId: state.selectedPatient?.id,
                                isLoadingDetail: state.isLoadingDetail,
                                onSelectPatient: _selectPatient,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 6,
                              child: _InlinePatientDetail(
                                patient: state.selectedPatient,
                                summary: state.selectedSummary,
                                timeline: state.timeline,
                                onEditPatient: _openEditPatient,
                                onOpenDetail: _openSelectedPatientDetail,
                              ),
                            ),
                          ],
                        )
                      : _PatientListCard(
                          patients: state.patients,
                          selectedPatientId: state.selectedPatient?.id,
                          isLoadingDetail: state.isLoadingDetail,
                          onSelectPatient: (patientId) async {
                            await _selectPatient(patientId);
                            if (!context.mounted) {
                              return;
                            }

                            await Navigator.of(context).pushNamed(
                              AppRouter.patientDetail,
                              arguments: PatientDetailRouteArgs(
                                patientId: patientId,
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _submitSearch(String value) {
    return ref.read(patientsControllerProvider.notifier).search(value);
  }

  Future<void> _selectPatient(String patientId) {
    return ref.read(patientsControllerProvider.notifier).selectPatient(patientId);
  }

  Future<void> _openNewPatient() async {
    final result = await Navigator.of(context).pushNamed(AppRouter.patientForm);
    if (!mounted || result is! String) {
      return;
    }

    await ref.read(patientsControllerProvider.notifier).selectPatient(result);
  }

  Future<void> _openEditPatient(Patient patient) async {
    final result = await Navigator.of(context).pushNamed(
      AppRouter.patientForm,
      arguments: PatientFormRouteArgs(patient: patient),
    );
    if (!mounted || result is! String) {
      return;
    }

    await ref.read(patientsControllerProvider.notifier).selectPatient(result);
  }

  Future<void> _openSelectedPatientDetail() async {
    final patientId = ref.read(patientsControllerProvider).valueOrNull?.selectedPatient?.id;
    if (patientId == null) {
      return;
    }

    await Navigator.of(context).pushNamed(
      AppRouter.patientDetail,
      arguments: PatientDetailRouteArgs(patientId: patientId),
    );
  }

  Future<void> _openAppointments() {
    return Navigator.of(context)
        .pushNamed(
          AppRouter.appointmentList,
          arguments: const AppointmentListRouteArgs(),
        )
        .then((_) {});
  }

  Future<void> _openEncounters() {
    return Navigator.of(context)
        .pushNamed(
          AppRouter.encounterList,
          arguments: const EncounterListRouteArgs(),
        )
        .then((_) {});
  }
}

class _PatientListAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _PatientListAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Patient registry'));
  }
}

class _PatientToolbar extends StatelessWidget {
  const _PatientToolbar({
    required this.searchController,
    required this.onSearch,
    required this.onClear,
    required this.onRefresh,
    required this.onCreatePatient,
    required this.onOpenAppointments,
    required this.onOpenEncounters,
    this.message,
    this.isSaving = false,
  });

  final TextEditingController searchController;
  final Future<void> Function(String value) onSearch;
  final VoidCallback onClear;
  final VoidCallback onRefresh;
  final VoidCallback onCreatePatient;
  final VoidCallback onOpenAppointments;
  final VoidCallback onOpenEncounters;
  final String? message;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 420,
                  child: TextField(
                    controller: searchController,
                    onSubmitted: onSearch,
                    decoration: InputDecoration(
                      labelText: 'Search by name, MRN, phone, or external reference',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchController.text.trim().isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: onClear,
                              icon: const Icon(Icons.clear),
                            ),
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => onSearch(searchController.text),
                  icon: const Icon(Icons.travel_explore_outlined),
                  label: const Text('Search'),
                ),
                OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Refresh'),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenAppointments,
                  icon: const Icon(Icons.event_note_outlined),
                  label: const Text('Appointments'),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenEncounters,
                  icon: const Icon(Icons.medical_information_outlined),
                  label: const Text('Encounter worklist'),
                ),
                FilledButton.tonalIcon(
                  onPressed: isSaving ? null : onCreatePatient,
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('New patient'),
                ),
              ],
            ),
            if (message?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PatientListCard extends StatelessWidget {
  const _PatientListCard({
    required this.patients,
    required this.selectedPatientId,
    required this.onSelectPatient,
    this.isLoadingDetail = false,
  });

  final List<Patient> patients;
  final String? selectedPatientId;
  final Future<void> Function(String patientId) onSelectPatient;
  final bool isLoadingDetail;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Registry list',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                if (isLoadingDetail)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (patients.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No patients matched the current filter.'),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: patients.length,
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    final selected = patient.id == selectedPatientId;
                    return ListTile(
                      selected: selected,
                      selectedTileColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      leading: CircleAvatar(
                        child: Icon(
                          patient.hasAlerts
                              ? Icons.warning_amber_outlined
                              : Icons.person_outline,
                        ),
                      ),
                      title: Text(patient.displayName),
                      subtitle: Text(
                        [
                          patient.medicalRecordNumber,
                          if (patient.phone?.trim().isNotEmpty ?? false)
                            patient.phone,
                          if (patient.clinicName?.trim().isNotEmpty ?? false)
                            patient.clinicName,
                        ].whereType<String>().join(' · '),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${patient.visitsCount} visits'),
                          if (patient.lastVisitAt != null)
                            Text(
                              DateFormat('dd MMM yyyy').format(patient.lastVisitAt!),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                        ],
                      ),
                      onTap: () => onSelectPatient(patient.id),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InlinePatientDetail extends StatelessWidget {
  const _InlinePatientDetail({
    required this.patient,
    required this.summary,
    required this.timeline,
    required this.onEditPatient,
    required this.onOpenDetail,
  });

  final Patient? patient;
  final PatientSummary? summary;
  final List<PatientVisitTimelineItem> timeline;
  final ValueChanged<Patient> onEditPatient;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    if (patient == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patient detail',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('Select a patient from the registry list to review the summary and visit timeline.'),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Selected patient',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: onOpenDetail,
              icon: const Icon(Icons.open_in_new_outlined),
              label: const Text('Open detail'),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => onEditPatient(patient!),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: PatientDetailContent(
              patient: patient!,
              summary: summary ?? PatientSummary.fromPatient(patient!),
              timeline: timeline,
            ),
          ),
        ),
      ],
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
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
