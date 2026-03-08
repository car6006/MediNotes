import '../../domain/entities/consent_template.dart';
import '../../domain/entities/patient_consent.dart';

class ConsentsState {
  const ConsentsState({
    this.patientId,
    this.appointmentId,
    this.templates = const [],
    this.history = const [],
    this.selectedTemplateId,
    this.isSubmitting = false,
    this.message,
  });

  final String? patientId;
  final String? appointmentId;
  final List<ConsentTemplate> templates;
  final List<PatientConsent> history;
  final String? selectedTemplateId;
  final bool isSubmitting;
  final String? message;

  ConsentsState copyWith({
    Object? patientId = _sentinel,
    Object? appointmentId = _sentinel,
    List<ConsentTemplate>? templates,
    List<PatientConsent>? history,
    Object? selectedTemplateId = _sentinel,
    bool? isSubmitting,
    Object? message = _sentinel,
  }) {
    return ConsentsState(
      patientId: identical(patientId, _sentinel) ? this.patientId : patientId as String?,
      appointmentId: identical(appointmentId, _sentinel)
          ? this.appointmentId
          : appointmentId as String?,
      templates: templates ?? this.templates,
      history: history ?? this.history,
      selectedTemplateId: identical(selectedTemplateId, _sentinel)
          ? this.selectedTemplateId
          : selectedTemplateId as String?,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      message: identical(message, _sentinel) ? this.message : message as String?,
    );
  }

  ConsentTemplate? get selectedTemplate {
    for (final template in templates) {
      if (template.id == selectedTemplateId) {
        return template;
      }
    }

    return templates.isEmpty ? null : templates.first;
  }

  static const Object _sentinel = Object();
}
