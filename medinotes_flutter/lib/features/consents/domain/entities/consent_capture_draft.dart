class ConsentCaptureDraft {
  const ConsentCaptureDraft({
    required this.patientId,
    required this.consentTemplateId,
    required this.acceptedBy,
    this.appointmentId,
    this.sourceChannel = 'admin_capture',
    this.acceptedPayload = const <String, dynamic>{},
    this.notes,
  });

  final String patientId;
  final String? appointmentId;
  final String consentTemplateId;
  final String acceptedBy;
  final String sourceChannel;
  final Map<String, dynamic> acceptedPayload;
  final String? notes;
}
