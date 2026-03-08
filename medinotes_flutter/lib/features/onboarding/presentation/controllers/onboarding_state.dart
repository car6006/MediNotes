import '../../domain/entities/onboarding_form.dart';
import '../../domain/entities/onboarding_response.dart';

class OnboardingState {
  const OnboardingState({
    this.patientId,
    this.appointmentId,
    this.forms = const [],
    this.responses = const [],
    this.selectedFormId,
    this.isSubmitting = false,
    this.message,
  });

  final String? patientId;
  final String? appointmentId;
  final List<OnboardingForm> forms;
  final List<OnboardingResponse> responses;
  final String? selectedFormId;
  final bool isSubmitting;
  final String? message;

  OnboardingState copyWith({
    Object? patientId = _sentinel,
    Object? appointmentId = _sentinel,
    List<OnboardingForm>? forms,
    List<OnboardingResponse>? responses,
    Object? selectedFormId = _sentinel,
    bool? isSubmitting,
    Object? message = _sentinel,
  }) {
    return OnboardingState(
      patientId: identical(patientId, _sentinel) ? this.patientId : patientId as String?,
      appointmentId: identical(appointmentId, _sentinel)
          ? this.appointmentId
          : appointmentId as String?,
      forms: forms ?? this.forms,
      responses: responses ?? this.responses,
      selectedFormId: identical(selectedFormId, _sentinel)
          ? this.selectedFormId
          : selectedFormId as String?,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      message: identical(message, _sentinel) ? this.message : message as String?,
    );
  }

  OnboardingForm? get selectedForm {
    for (final form in forms) {
      if (form.id == selectedFormId) {
        return form;
      }
    }

    return forms.isEmpty ? null : forms.first;
  }

  static const Object _sentinel = Object();
}
