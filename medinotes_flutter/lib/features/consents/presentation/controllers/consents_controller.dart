import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/consents_repository_impl.dart';
import '../../domain/entities/consent_capture_draft.dart';
import '../../domain/entities/patient_consent.dart';
import '../../domain/repositories/consents_repository.dart';
import 'consents_state.dart';

final consentsRepositoryProvider = Provider<ConsentsRepository>((ref) {
  return ConsentsRepositoryImpl();
});

final consentsControllerProvider =
    AsyncNotifierProvider<ConsentsController, ConsentsState>(
      ConsentsController.new,
    );

class ConsentsController extends AsyncNotifier<ConsentsState> {
  late final ConsentsRepository _repository;

  @override
  Future<ConsentsState> build() async {
    _repository = ref.read(consentsRepositoryProvider);
    final templates = await _repository.loadTemplates();
    return ConsentsState(
      templates: templates,
      selectedTemplateId: templates.isEmpty ? null : templates.first.id,
      message: templates.isEmpty ? 'No consent templates are available.' : 'Consent templates loaded.',
    );
  }

  Future<void> load(String patientId, {String? appointmentId}) async {
    final current = state.valueOrNull ?? const ConsentsState();
    state = AsyncValue.data(
      current.copyWith(
        patientId: patientId,
        appointmentId: appointmentId,
        message: 'Loading consents...',
      ),
    );

    final templates = await _repository.loadTemplates();
    final history = await _repository.loadPatientConsents(patientId);
    final selectedTemplateId = current.selectedTemplateId ?? (templates.isEmpty ? null : templates.first.id);

    state = AsyncValue.data(
      current.copyWith(
        patientId: patientId,
        appointmentId: appointmentId,
        templates: templates,
        history: history,
        selectedTemplateId: selectedTemplateId,
        message: history.isEmpty ? 'Ready to capture consent.' : 'Consent history loaded.',
      ),
    );
  }

  void selectTemplate(String? templateId) {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    state = AsyncValue.data(current.copyWith(selectedTemplateId: templateId));
  }

  Future<PatientConsent> capture(ConsentCaptureDraft draft) async {
    final current = state.valueOrNull ?? const ConsentsState();
    state = AsyncValue.data(current.copyWith(isSubmitting: true, message: null));

    final consent = await _repository.captureConsent(draft);
    await load(draft.patientId, appointmentId: draft.appointmentId);

    final latest = state.valueOrNull ?? current;
    state = AsyncValue.data(
      latest.copyWith(isSubmitting: false, message: 'Consent captured.'),
    );

    return consent;
  }
}
