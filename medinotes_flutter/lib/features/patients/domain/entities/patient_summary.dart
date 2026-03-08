import 'patient.dart';

class PatientSummary {
  const PatientSummary({
    required this.id,
    required this.fullName,
    required this.medicalRecordNumber,
    this.preferredName,
    this.clinicName,
    this.phone,
    this.email,
    this.dateOfBirth,
    this.sex,
    this.medicalHistorySummary,
    this.allergiesSummary,
    this.medicationSummary,
    this.alerts = const [],
    this.hasAlerts = false,
    this.lastVisitAt,
    this.visitsCount = 0,
  });

  final String id;
  final String fullName;
  final String medicalRecordNumber;
  final String? preferredName;
  final String? clinicName;
  final String? phone;
  final String? email;
  final DateTime? dateOfBirth;
  final String? sex;
  final String? medicalHistorySummary;
  final String? allergiesSummary;
  final String? medicationSummary;
  final List<String> alerts;
  final bool hasAlerts;
  final DateTime? lastVisitAt;
  final int visitsCount;

  factory PatientSummary.fromPatient(Patient patient) {
    return PatientSummary(
      id: patient.id,
      fullName: patient.fullName,
      medicalRecordNumber: patient.medicalRecordNumber,
      preferredName: patient.preferredName,
      clinicName: patient.clinicName,
      phone: patient.phone,
      email: patient.email,
      dateOfBirth: patient.dateOfBirth,
      sex: patient.sex,
      medicalHistorySummary: patient.medicalHistorySummary,
      allergiesSummary: patient.allergiesSummary,
      medicationSummary: patient.medicationSummary,
      alerts: patient.alerts,
      hasAlerts: patient.hasAlerts,
      lastVisitAt: patient.lastVisitAt,
      visitsCount: patient.visitsCount,
    );
  }
}
