class OnboardingResponse {
  const OnboardingResponse({
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
}
