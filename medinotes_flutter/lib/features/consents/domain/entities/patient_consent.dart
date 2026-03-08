class PatientConsent {
  const PatientConsent({
    required this.id,
    required this.patientId,
    required this.consentTemplateId,
    required this.templateTitle,
    required this.templateVersion,
    required this.acceptedBy,
    required this.sourceChannel,
    required this.acceptedAt,
    this.appointmentId,
    this.notes,
    this.templateSnapshot = const <String, dynamic>{},
  });

  final String id;
  final String patientId;
  final String? appointmentId;
  final String consentTemplateId;
  final String templateTitle;
  final String templateVersion;
  final String acceptedBy;
  final String sourceChannel;
  final DateTime acceptedAt;
  final String? notes;
  final Map<String, dynamic> templateSnapshot;
}
