class PatientDraft {
  const PatientDraft({
    this.clinicId,
    this.medicalRecordNumber,
    required this.firstName,
    required this.lastName,
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
    this.notes,
  });

  final String? clinicId;
  final String? medicalRecordNumber;
  final String firstName;
  final String lastName;
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
  final String? notes;
}
