class OnboardingSubmission {
  const OnboardingSubmission({
    required this.patientId,
    required this.onboardingFormId,
    required this.responses,
    this.appointmentId,
    this.sourceChannel = 'admin_capture',
  });

  final String patientId;
  final String? appointmentId;
  final String onboardingFormId;
  final String sourceChannel;
  final Map<String, dynamic> responses;
}
