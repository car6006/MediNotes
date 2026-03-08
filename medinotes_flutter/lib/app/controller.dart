import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'repository.dart';
import 'session_controller.dart';

final clinicRepositoryProvider = Provider<ClinicRepository>((ref) {
  return ClinicRepository();
});

final clinicControllerProvider =
    AsyncNotifierProvider<ClinicController, ClinicState>(ClinicController.new);

class ClinicController extends AsyncNotifier<ClinicState> {
  late final ClinicRepository _repository;

  @override
  Future<ClinicState> build() async {
    final session = await ref.watch(sessionControllerProvider.future);
    _repository = ref.read(clinicRepositoryProvider);

    if (session == null) {
      return const ClinicState(
        syncMessage: 'Sign in required before opening the clinical workspace.',
      );
    }

    return _repository.bootstrap();
  }

  ClinicRepository get repository => _repository;

  Future<void> syncNow() async {
    await _run((current) => _repository.syncNow(current));
  }

  Future<void> searchPatients(String query) async {
    await _run((current) => _repository.searchPatients(current, query));
  }

  Future<void> loadPatientHistory(String patientId) async {
    await _run((current) => _repository.loadPatientHistory(current, patientId));
  }

  Future<void> savePatient(PatientRecord patient) async {
    await _run((current) => _repository.upsertPatient(current, patient));
  }

  Future<void> saveVisit(VisitRecord visit) async {
    await _run((current) => _repository.upsertVisit(current, visit));
  }

  Future<void> saveTemplate(NoteTemplateRecord template) async {
    await _run((current) => _repository.upsertTemplate(current, template));
  }

  Future<void> saveDictation(DictationCapture dictation) async {
    await _run((current) => _repository.createDictation(current, dictation));
  }

  Future<void> _run(
    Future<ClinicState> Function(ClinicState current) operation,
  ) async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    state = AsyncValue.data(current.copyWith(isSyncing: true));

    final next = await operation(current);
    state = AsyncValue.data(next);
  }
}
