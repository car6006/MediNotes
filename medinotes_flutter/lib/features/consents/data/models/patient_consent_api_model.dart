import '../../domain/entities/patient_consent.dart';

class PatientConsentApiModel {
  const PatientConsentApiModel({
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

  PatientConsent toEntity() {
    return PatientConsent(
      id: id,
      patientId: patientId,
      appointmentId: appointmentId,
      consentTemplateId: consentTemplateId,
      templateTitle: templateTitle,
      templateVersion: templateVersion,
      acceptedBy: acceptedBy,
      sourceChannel: sourceChannel,
      acceptedAt: acceptedAt,
      notes: notes,
      templateSnapshot: templateSnapshot,
    );
  }

  factory PatientConsentApiModel.fromJson(Map<String, dynamic> json) {
    final template = _map(json['template']);
    return PatientConsentApiModel(
      id: (json['id'] ?? '').toString(),
      patientId: (json['patient_id'] ?? '').toString(),
      appointmentId: json['appointment_id'] as String?,
      consentTemplateId: (json['consent_template_id'] ?? template['id'] ?? '').toString(),
      templateTitle: (template['title'] ?? '').toString(),
      templateVersion: (json['template_version'] ?? template['version'] ?? '1.0').toString(),
      acceptedBy: (json['accepted_by'] ?? '').toString(),
      sourceChannel: (json['source_channel'] ?? 'admin_capture').toString(),
      acceptedAt: _parseDate(json['accepted_at']) ?? DateTime.now(),
      notes: json['notes'] as String?,
      templateSnapshot: _map(json['template_snapshot']),
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
