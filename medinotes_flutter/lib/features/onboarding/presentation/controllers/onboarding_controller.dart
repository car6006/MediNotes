import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/onboarding_repository_impl.dart';
import '../../domain/entities/onboarding_response.dart';
import '../../domain/entities/onboarding_submission.dart';
import '../../domain/repositories/onboarding_repository.dart';
import 'onboarding_state.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepositoryImpl();
});

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );

class OnboardingController extends AsyncNotifier<OnboardingState> {
  late final OnboardingRepository _repository;

  @override
  Future<OnboardingState> build() async {
    _repository = ref.read(onboardingRepositoryProvider);
    final forms = await _repository.loadForms();
    return OnboardingState(
      forms: forms,
      selectedFormId: forms.isEmpty ? null : forms.first.id,
      message: forms.isEmpty
          ? 'No onboarding forms are available.'
          : 'Onboarding forms loaded.',
    );
  }

  Future<void> load(String patientId, {String? appointmentId}) async {
    final current = state.valueOrNull ?? const OnboardingState();
    state = AsyncValue.data(
      current.copyWith(
        patientId: patientId,
        appointmentId: appointmentId,
        message: 'Loading onboarding...',
      ),
    );

    final forms = await _repository.loadForms();
    final responses = await _repository.loadPatientResponses(patientId);
    final selectedFormId = current.selectedFormId ?? (forms.isEmpty ? null : forms.first.id);

    state = AsyncValue.data(
      current.copyWith(
        patientId: patientId,
        appointmentId: appointmentId,
        forms: forms,
        responses: responses,
        selectedFormId: selectedFormId,
        message: responses.isEmpty
            ? 'Ready to capture onboarding.'
            : 'Onboarding history loaded.',
      ),
    );
  }

  void selectForm(String? formId) {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    state = AsyncValue.data(current.copyWith(selectedFormId: formId));
  }

  Future<OnboardingResponse> submit(OnboardingSubmission submission) async {
    final current = state.valueOrNull ?? const OnboardingState();
    state = AsyncValue.data(current.copyWith(isSubmitting: true, message: null));

    final response = await _repository.submit(submission);
    await load(submission.patientId, appointmentId: submission.appointmentId);

    final latest = state.valueOrNull ?? current;
    state = AsyncValue.data(
      latest.copyWith(isSubmitting: false, message: 'Onboarding submitted.'),
    );

    return response;
  }
}
