class Patient {
  const Patient({
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

  String get fullName => '$firstName $lastName'.trim();

  String get displayName {
    final preferred = preferredName?.trim();
    if (preferred != null && preferred.isNotEmpty) {
      return '$preferred $lastName'.trim();
    }

    return fullName;
  }

  String get addressSummary {
    return [addressLine1, addressLine2, city, province, postalCode, country]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join(', ');
  }

  int? get age {
    if (dateOfBirth == null) {
      return null;
    }

    final now = DateTime.now();
    var years = now.year - dateOfBirth!.year;
    final birthdayThisYear = DateTime(
      now.year,
      dateOfBirth!.month,
      dateOfBirth!.day,
    );

    if (birthdayThisYear.isAfter(now)) {
      years -= 1;
    }

    return years;
  }

  Patient copyWith({
    String? id,
    String? medicalRecordNumber,
    String? firstName,
    String? lastName,
    String? clinicId,
    String? clinicName,
    String? title,
    String? middleName,
    String? preferredName,
    DateTime? dateOfBirth,
    String? sex,
    String? phone,
    String? alternatePhone,
    String? email,
    String? nationalIdNumber,
    String? passportNumber,
    String? externalReference,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? province,
    String? postalCode,
    String? country,
    String? emergencyContactName,
    String? emergencyContactPhone,
    List<String>? allergies,
    String? allergiesSummary,
    List<String>? medications,
    String? medicationSummary,
    List<String>? medicalHistory,
    String? medicalHistorySummary,
    List<String>? alerts,
    bool? hasAlerts,
    String? notes,
    DateTime? lastVisitAt,
    int? visitsCount,
  }) {
    return Patient(
      id: id ?? this.id,
      medicalRecordNumber: medicalRecordNumber ?? this.medicalRecordNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      clinicId: clinicId ?? this.clinicId,
      clinicName: clinicName ?? this.clinicName,
      title: title ?? this.title,
      middleName: middleName ?? this.middleName,
      preferredName: preferredName ?? this.preferredName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      sex: sex ?? this.sex,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      email: email ?? this.email,
      nationalIdNumber: nationalIdNumber ?? this.nationalIdNumber,
      passportNumber: passportNumber ?? this.passportNumber,
      externalReference: externalReference ?? this.externalReference,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      province: province ?? this.province,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      emergencyContactName:
          emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      allergies: allergies ?? this.allergies,
      allergiesSummary: allergiesSummary ?? this.allergiesSummary,
      medications: medications ?? this.medications,
      medicationSummary: medicationSummary ?? this.medicationSummary,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      medicalHistorySummary:
          medicalHistorySummary ?? this.medicalHistorySummary,
      alerts: alerts ?? this.alerts,
      hasAlerts: hasAlerts ?? this.hasAlerts,
      notes: notes ?? this.notes,
      lastVisitAt: lastVisitAt ?? this.lastVisitAt,
      visitsCount: visitsCount ?? this.visitsCount,
    );
  }
}
