import '../../domain/entities/patient.dart';

class PatientApiModel {
  const PatientApiModel({
    required this.id,
    required this.medicalRecordNumber,
    required this.firstName,
    required this.lastName,
    this.clinicId,
    this.clinicName,
    this.title,
    this.middleName,
    this.preferredName,
    this.dateOfBirth,
    this.sex,
    this.phone,
    this.alternatePhone,
    this.email,
    this.nationalIdNumber,
    this.passportNumber,
    this.externalReference,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.province,
    this.postalCode,
    this.country,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.allergies = const [],
    this.allergiesSummary,
    this.medications = const [],
    this.medicationSummary,
    this.medicalHistory = const [],
    this.medicalHistorySummary,
    this.alerts = const [],
    this.hasAlerts = false,
    this.notes,
    this.lastVisitAt,
    this.visitsCount = 0,
  });

  final String id;
  final String medicalRecordNumber;
  final String firstName;
  final String lastName;
  final String? clinicId;
  final String? clinicName;
  final String? title;
  final String? middleName;
  final String? preferredName;
  final DateTime? dateOfBirth;
  final String? sex;
  final String? phone;
  final String? alternatePhone;
  final String? email;
  final String? nationalIdNumber;
  final String? passportNumber;
  final String? externalReference;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? province;
  final String? postalCode;
  final String? country;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final List<String> allergies;
  final String? allergiesSummary;
  final List<String> medications;
  final String? medicationSummary;
  final List<String> medicalHistory;
  final String? medicalHistorySummary;
  final List<String> alerts;
  final bool hasAlerts;
  final String? notes;
  final DateTime? lastVisitAt;
  final int visitsCount;

  Patient toEntity() {
    return Patient(
      id: id,
      medicalRecordNumber: medicalRecordNumber,
      firstName: firstName,
      lastName: lastName,
      clinicId: clinicId,
      clinicName: clinicName,
      title: title,
      middleName: middleName,
      preferredName: preferredName,
      dateOfBirth: dateOfBirth,
      sex: sex,
      phone: phone,
      alternatePhone: alternatePhone,
      email: email,
      nationalIdNumber: nationalIdNumber,
      passportNumber: passportNumber,
      externalReference: externalReference,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      province: province,
      postalCode: postalCode,
      country: country,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      allergies: allergies,
      allergiesSummary: allergiesSummary,
      medications: medications,
      medicationSummary: medicationSummary,
      medicalHistory: medicalHistory,
      medicalHistorySummary: medicalHistorySummary,
      alerts: alerts,
      hasAlerts: hasAlerts,
      notes: notes,
      lastVisitAt: lastVisitAt,
      visitsCount: visitsCount,
    );
  }

  factory PatientApiModel.fromJson(Map<String, dynamic> json) {
    final clinic = _asMap(json['clinic']);
    final identifiers = _asMap(json['identifiers']);
    final demographics = _asMap(json['demographics']);
    final contact = _asMap(json['contact']);
    final summaries = _asMap(json['summaries']);
    final alerts = _strings(json['alerts']);

    return PatientApiModel(
      id: json['id'] as String,
      clinicId: (json['clinic_id'] ?? clinic['id']) as String?,
      clinicName: clinic['name'] as String?,
      medicalRecordNumber:
          (json['medical_record_number'] ?? identifiers['medical_record_number'] ?? '')
              .toString(),
      title: (json['title'] ?? demographics['title']) as String?,
      firstName:
          (json['first_name'] ?? demographics['first_name'] ?? '').toString(),
      middleName:
          (json['middle_name'] ?? demographics['middle_name']) as String?,
      lastName:
          (json['last_name'] ?? demographics['last_name'] ?? '').toString(),
      preferredName:
          (json['preferred_name'] ?? demographics['preferred_name']) as String?,
      dateOfBirth: _parseDate(json['date_of_birth'] ?? demographics['date_of_birth']),
      sex: (json['sex'] ?? demographics['sex']) as String?,
      phone: (json['phone'] ?? contact['phone']) as String?,
      alternatePhone:
          (json['alternate_phone'] ?? contact['alternate_phone']) as String?,
      email: (json['email'] ?? contact['email']) as String?,
      nationalIdNumber:
          (json['national_id_number'] ?? identifiers['national_id_number'])
              as String?,
      passportNumber:
          (json['passport_number'] ?? identifiers['passport_number']) as String?,
      externalReference:
          (json['external_reference'] ?? identifiers['external_reference'])
              as String?,
      addressLine1:
          (json['address_line_1'] ?? contact['address_line_1']) as String?,
      addressLine2:
          (json['address_line_2'] ?? contact['address_line_2']) as String?,
      city: (json['city'] ?? contact['city']) as String?,
      province: (json['province'] ?? contact['province']) as String?,
      postalCode: (json['postal_code'] ?? contact['postal_code']) as String?,
      country: (json['country'] ?? contact['country']) as String?,
      emergencyContactName:
          (json['emergency_contact_name'] ?? contact['emergency_contact_name'])
              as String?,
      emergencyContactPhone:
          (json['emergency_contact_phone'] ?? contact['emergency_contact_phone'])
              as String?,
      allergies: _strings(json['allergies']),
      allergiesSummary:
          (json['allergies_summary'] ?? summaries['allergies']) as String?,
      medications: _strings(json['medications']),
      medicationSummary:
          (json['medication_summary'] ?? summaries['medications']) as String?,
      medicalHistory: _strings(json['medical_history']),
      medicalHistorySummary:
          (json['medical_history_summary'] ?? summaries['medical_history'])
              as String?,
      alerts: alerts,
      hasAlerts: json['has_alerts'] as bool? ?? alerts.isNotEmpty,
      notes: json['notes'] as String?,
      lastVisitAt: _parseDate(json['last_visit_at']),
      visitsCount:
          (json['visits_count'] as num?)?.toInt() ??
          ((json['visits'] as List?)?.length ?? 0),
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return const <String, dynamic>{};
}

List<String> _strings(Object? value) {
  if (value is! List) {
    return const <String>[];
  }

  return value
      .map((item) => item.toString())
      .where((item) => item.trim().isNotEmpty)
      .toList();
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
