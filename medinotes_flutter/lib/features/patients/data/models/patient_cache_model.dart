import '../../../../app/models.dart';
import '../../domain/entities/patient.dart';

class PatientCacheModel {
  const PatientCacheModel({required this.record});

  final PatientRecord record;

  Patient toEntity() {
    return Patient(
      id: record.id,
      medicalRecordNumber: record.medicalRecordNumber,
      firstName: record.firstName,
      lastName: record.lastName,
      clinicId: record.clinicId,
      clinicName: record.clinicName,
      title: record.title,
      middleName: record.middleName,
      preferredName: record.preferredName,
      dateOfBirth: record.dateOfBirth,
      sex: record.sex,
      phone: record.phone,
      alternatePhone: record.alternatePhone,
      email: record.email,
      nationalIdNumber: record.nationalIdNumber,
      passportNumber: record.passportNumber,
      externalReference: record.externalReference,
      addressLine1: record.addressLine1,
      addressLine2: record.addressLine2,
      city: record.city,
      province: record.province,
      postalCode: record.postalCode,
      country: record.country,
      emergencyContactName: record.emergencyContactName,
      emergencyContactPhone: record.emergencyContactPhone,
      allergies: record.allergies,
      allergiesSummary: record.allergiesSummary,
      medications: record.medications,
      medicationSummary: record.medicationSummary,
      medicalHistory: record.medicalHistory,
      medicalHistorySummary: record.medicalHistorySummary,
      alerts: record.alerts,
      hasAlerts: record.hasAlerts,
      notes: record.notes,
      lastVisitAt: record.lastVisitAt,
      visitsCount: record.visitsCount,
    );
  }

  factory PatientCacheModel.fromEntity(Patient patient) {
    return PatientCacheModel(
      record: PatientRecord(
        id: patient.id,
        clinicId: patient.clinicId,
        clinicName: patient.clinicName,
        medicalRecordNumber: patient.medicalRecordNumber,
        title: patient.title,
        firstName: patient.firstName,
        middleName: patient.middleName,
        lastName: patient.lastName,
        preferredName: patient.preferredName,
        dateOfBirth: patient.dateOfBirth,
        sex: patient.sex,
        phone: patient.phone,
        alternatePhone: patient.alternatePhone,
        email: patient.email,
        nationalIdNumber: patient.nationalIdNumber,
        passportNumber: patient.passportNumber,
        externalReference: patient.externalReference,
        addressLine1: patient.addressLine1,
        addressLine2: patient.addressLine2,
        city: patient.city,
        province: patient.province,
        postalCode: patient.postalCode,
        country: patient.country,
        emergencyContactName: patient.emergencyContactName,
        emergencyContactPhone: patient.emergencyContactPhone,
        allergies: patient.allergies,
        allergiesSummary: patient.allergiesSummary,
        medications: patient.medications,
        medicationSummary: patient.medicationSummary,
        medicalHistory: patient.medicalHistory,
        medicalHistorySummary: patient.medicalHistorySummary,
        notes: patient.notes,
        alerts: patient.alerts,
        hasAlerts: patient.hasAlerts,
        lastVisitAt: patient.lastVisitAt,
        visitsCount: patient.visitsCount,
      ),
    );
  }

  factory PatientCacheModel.fromRecord(PatientRecord record) {
    return PatientCacheModel(record: record);
  }
}
