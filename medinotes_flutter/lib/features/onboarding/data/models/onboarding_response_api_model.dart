import '../../domain/entities/onboarding_response.dart';

class OnboardingResponseApiModel {
  const OnboardingResponseApiModel({
    required this.id,
    required this.patientId,
    required this.formId,
    required this.formTitle,
    required this.sourceChannel,
    required this.responses,
    required this.submittedAt,
    this.appointmentId,
  });

  final String id;
  final String patientId;
  final String? appointmentId;
  final String formId;
  final String formTitle;
  final String sourceChannel;
  final Map<String, dynamic> responses;
  final DateTime submittedAt;

  OnboardingResponse toEntity() {
    return OnboardingResponse(
      id: id,
      patientId: patientId,
      appointmentId: appointmentId,
      formId: formId,
      formTitle: formTitle,
      sourceChannel: sourceChannel,
      responses: responses,
      submittedAt: submittedAt,
    );
  }

  factory OnboardingResponseApiModel.fromJson(Map<String, dynamic> json) {
    final form = _map(json['form']);
    return OnboardingResponseApiModel(
      id: (json['id'] ?? '').toString(),
      patientId: (json['patient_id'] ?? '').toString(),
      appointmentId: json['appointment_id'] as String?,
      formId: (json['onboarding_form_id'] ?? form['id'] ?? '').toString(),
      formTitle: (form['title'] ?? '').toString(),
      sourceChannel: (json['source_channel'] ?? 'admin_capture').toString(),
      responses: _map(json['responses']),
      submittedAt: _parseDate(json['submitted_at']) ?? DateTime.now(),
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return const <String, dynamic>{};
}

DateTime? _parseDate(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.tryParse(value.toString());
}
