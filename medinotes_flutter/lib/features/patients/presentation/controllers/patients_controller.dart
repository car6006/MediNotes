import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/controller.dart';
import '../../data/repositories/patients_repository_impl.dart';
import '../../domain/entities/patient.dart';
import '../../domain/entities/patient_draft.dart';
import '../../domain/entities/patient_summary.dart';
import '../../domain/entities/patient_visit_timeline_item.dart';
import '../../domain/repositories/patients_repository.dart';
import 'patients_state.dart';

final patientsRepositoryProvider = Provider<PatientsRepository>((ref) {
  return PatientsRepositoryImpl();
});

final patientsControllerProvider =
    AsyncNotifierProvider<PatientsController, PatientsState>(
      PatientsController.new,
    );

class PatientsController extends AsyncNotifier<PatientsState> {
  late final PatientsRepository _repository;

  @override
  Future<PatientsState> build() async {
    _repository = ref.read(patientsRepositoryProvider);

    final patients = await _repository.loadPatients();
    if (patients.isEmpty) {
      return const PatientsState(message: 'No patients have been captured yet.');
    }

    final selected = await _repository.loadPatientDetail(patients.first.id) ??
        patients.first;
    final summary = await _repository.loadPatientSummary(selected.id) ??
        PatientSummary.fromPatient(selected);
    final timeline = await _repository.loadPatientTimeline(selected.id);

    return PatientsState(
      patients: patients,
      selectedPatient: selected,
      selectedSummary: summary,
      timeline: timeline,
      message: 'Patient registry loaded.',
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull ?? const PatientsState();
    state = AsyncValue.data(
      current.copyWith(message: 'Refreshing patient registry...'),
    );

    final patients = await _repository.loadPatients();
    await _applySelection(
      patients: patients,
      preferredPatientId: current.selectedPatient?.id,
      query: current.query,
      message: 'Patient registry refreshed.',
    );
  }

  Future<void> search(String query) async {
    final current = state.valueOrNull ?? const PatientsState();
    state = AsyncValue.data(
      current.copyWith(query: query, message: 'Searching patients...'),
    );

    final patients = query.trim().isEmpty
        ? await _repository.loadPatients()
        : await _repository.searchPatients(query);

    await _applySelection(
      patients: patients,
      preferredPatientId: current.selectedPatient?.id,
      query: query,
      message: query.trim().isEmpty
          ? 'Showing patient registry.'
          : 'Patient search updated.',
    );
  }

  Future<void> selectPatient(String patientId) async {
    final current = state.valueOrNull ?? const PatientsState();
    state = AsyncValue.data(current.copyWith(isLoadingDetail: true));

    final cached = _findPatient(current.patients, patientId);
    final selected = await _repository.loadPatientDetail(patientId) ?? cached;
    final summary = await _repository.loadPatientSummary(patientId) ??
        (selected == null ? null : PatientSummary.fromPatient(selected));
    final timeline = await _repository.loadPatientTimeline(patientId);

    state = AsyncValue.data(
      current.copyWith(
        selectedPatient: selected,
        selectedSummary: summary,
        timeline: timeline,
        isLoadingDetail: false,
        message: selected == null ? current.message : 'Patient details loaded.',
      ),
    );
  }

  Future<String> createPatient(PatientDraft draft) async {
    final current = state.valueOrNull ?? const PatientsState();
    state = AsyncValue.data(current.copyWith(isSaving: true, message: null));

    final patient = await _repository.createPatient(draft);
    final patients = await _repository.loadPatients();
    final summary = await _repository.loadPatientSummary(patient.id) ??
        PatientSummary.fromPatient(patient);
    final timeline = await _repository.loadPatientTimeline(patient.id);

    ref.invalidate(clinicControllerProvider);

    state = AsyncValue.data(
      current.copyWith(
        patients: patients,
        selectedPatient: patient,
        selectedSummary: summary,
        timeline: timeline,
        isSaving: false,
        message: 'Patient created successfully.',
      ),
    );

    return patient.id;
  }

  Future<String> updatePatient(String patientId, PatientDraft draft) async {
    final current = state.valueOrNull ?? const PatientsState();
    state = AsyncValue.data(current.copyWith(isSaving: true, message: null));

    final patient = await _repository.updatePatient(patientId, draft);
    final patients = await _repository.loadPatients();
    final summary = await _repository.loadPatientSummary(patient.id) ??
        PatientSummary.fromPatient(patient);
    final timeline = await _repository.loadPatientTimeline(patient.id);

    ref.invalidate(clinicControllerProvider);

    state = AsyncValue.data(
      current.copyWith(
        patients: patients,
        selectedPatient: patient,
        selectedSummary: summary,
        timeline: timeline,
        isSaving: false,
        message: 'Patient updated successfully.',
      ),
    );

    return patient.id;
  }

  Future<void> _applySelection({
    required List<Patient> patients,
    required String? preferredPatientId,
    required String query,
    required String message,
  }) async {
    final selected = _findPatient(patients, preferredPatientId) ??
        (patients.isNotEmpty ? patients.first : null);

    final summary = selected == null
        ? null
        : await _repository.loadPatientSummary(selected.id) ??
              PatientSummary.fromPatient(selected);
    final timeline = selected == null
      ? const <PatientVisitTimelineItem>[]
        : await _repository.loadPatientTimeline(selected.id);

    state = AsyncValue.data(
      PatientsState(
        patients: patients,
        query: query,
        selectedPatient: selected,
        selectedSummary: summary,
        timeline: timeline,
        message: patients.isEmpty ? 'No patients matched the current filter.' : message,
      ),
    );
  }

  Patient? _findPatient(List<Patient> patients, String? patientId) {
    if (patientId == null) {
      return null;
    }

    for (final patient in patients) {
      if (patient.id == patientId) {
        return patient;
      }
    }

    return null;
  }
}
