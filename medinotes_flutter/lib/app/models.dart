import 'dart:convert';

enum SyncOperation {
  upsertPatient,
  upsertVisit,
  upsertTemplate,
  createDictation,
}

class PatientRecord {
  const PatientRecord({
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
    this.notes,
  this.alerts = const [],
  this.hasAlerts = false,
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
  final String? notes;
  final List<String> alerts;
  final bool hasAlerts;
  final DateTime? lastVisitAt;
  final int visitsCount;

  String get fullName => '$firstName $lastName'.trim();

  PatientRecord copyWith({
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
    String? notes,
  List<String>? alerts,
  bool? hasAlerts,
    DateTime? lastVisitAt,
    int? visitsCount,
  }) {
    return PatientRecord(
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
    emergencyContactName: emergencyContactName ?? this.emergencyContactName,
    emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      allergies: allergies ?? this.allergies,
    allergiesSummary: allergiesSummary ?? this.allergiesSummary,
      medications: medications ?? this.medications,
    medicationSummary: medicationSummary ?? this.medicationSummary,
      medicalHistory: medicalHistory ?? this.medicalHistory,
    medicalHistorySummary:
      medicalHistorySummary ?? this.medicalHistorySummary,
      notes: notes ?? this.notes,
    alerts: alerts ?? this.alerts,
    hasAlerts: hasAlerts ?? this.hasAlerts,
      lastVisitAt: lastVisitAt ?? this.lastVisitAt,
      visitsCount: visitsCount ?? this.visitsCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    'clinic_id': clinicId,
      'medical_record_number': medicalRecordNumber,
    'title': title,
      'first_name': firstName,
    'middle_name': middleName,
      'last_name': lastName,
    'preferred_name': preferredName,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'sex': sex,
      'phone': phone,
    'alternate_phone': alternatePhone,
      'email': email,
    'national_id_number': nationalIdNumber,
    'passport_number': passportNumber,
    'external_reference': externalReference,
    'address_line_1': addressLine1,
    'address_line_2': addressLine2,
    'city': city,
    'province': province,
    'postal_code': postalCode,
    'country': country,
    'emergency_contact_name': emergencyContactName,
    'emergency_contact_phone': emergencyContactPhone,
      'allergies': allergies,
    'allergies_summary': allergiesSummary,
      'medications': medications,
    'medication_summary': medicationSummary,
      'medical_history': medicalHistory,
    'medical_history_summary': medicalHistorySummary,
      'notes': notes,
    'alerts': alerts,
    'has_alerts': hasAlerts,
      'last_visit_at': lastVisitAt?.toIso8601String(),
      'visits_count': visitsCount,
    };
  }

  factory PatientRecord.fromJson(Map<String, dynamic> json) {
  final clinic = json['clinic'];
  final identifiers = json['identifiers'];
  final demographics = json['demographics'];
  final contact = json['contact'];
  final summaries = json['summaries'];
  final alerts = _stringList(json['alerts']);

    return PatientRecord(
      id: json['id'] as String,
    clinicId:
      json['clinic_id'] as String? ??
      (clinic is Map<String, dynamic> ? clinic['id'] as String? : null),
    clinicName: clinic is Map<String, dynamic> ? clinic['name'] as String? : null,
    medicalRecordNumber:
      (json['medical_record_number'] ??
          (identifiers is Map<String, dynamic>
            ? identifiers['medical_record_number']
            : ''))
        as String,
    title:
      json['title'] as String? ??
      (demographics is Map<String, dynamic>
        ? demographics['title'] as String?
        : null),
    firstName:
      (json['first_name'] ??
          (demographics is Map<String, dynamic>
            ? demographics['first_name']
            : ''))
        as String,
    middleName:
      json['middle_name'] as String? ??
      (demographics is Map<String, dynamic>
        ? demographics['middle_name'] as String?
        : null),
    lastName:
      (json['last_name'] ??
          (demographics is Map<String, dynamic>
            ? demographics['last_name']
            : ''))
        as String,
    preferredName:
      json['preferred_name'] as String? ??
      (demographics is Map<String, dynamic>
        ? demographics['preferred_name'] as String?
        : null),
    dateOfBirth: _tryParseDate(
    json['date_of_birth'] ??
      (demographics is Map<String, dynamic>
        ? demographics['date_of_birth']
        : null),
    ),
    sex:
      json['sex'] as String? ??
      (demographics is Map<String, dynamic>
        ? demographics['sex'] as String?
        : null),
    phone:
      json['phone'] as String? ??
      (contact is Map<String, dynamic>
        ? contact['phone'] as String?
        : null),
    alternatePhone:
      json['alternate_phone'] as String? ??
      (contact is Map<String, dynamic>
        ? contact['alternate_phone'] as String?
        : null),
    email:
      json['email'] as String? ??
      (contact is Map<String, dynamic>
        ? contact['email'] as String?
        : null),
    nationalIdNumber:
      json['national_id_number'] as String? ??
      (identifiers is Map<String, dynamic>
        ? identifiers['national_id_number'] as String?
        : null),
    passportNumber:
      json['passport_number'] as String? ??
      (identifiers is Map<String, dynamic>
        ? identifiers['passport_number'] as String?
        : null),
    externalReference:
      json['external_reference'] as String? ??
      (identifiers is Map<String, dynamic>
        ? identifiers['external_reference'] as String?
        : null),
    addressLine1:
      json['address_line_1'] as String? ??
      (contact is Map<String, dynamic>
        ? contact['address_line_1'] as String?
        : null),
    addressLine2:
      json['address_line_2'] as String? ??
      (contact is Map<String, dynamic>
        ? contact['address_line_2'] as String?
        : null),
    city:
      json['city'] as String? ??
      (contact is Map<String, dynamic>
        ? contact['city'] as String?
        : null),
    province:
      json['province'] as String? ??
      (contact is Map<String, dynamic>
        ? contact['province'] as String?
        : null),
    postalCode:
      json['postal_code'] as String? ??
      (contact is Map<String, dynamic>
        ? contact['postal_code'] as String?
        : null),
    country:
      json['country'] as String? ??
      (contact is Map<String, dynamic>
        ? contact['country'] as String?
        : null),
    emergencyContactName:
      json['emergency_contact_name'] as String? ??
      (contact is Map<String, dynamic>
        ? contact['emergency_contact_name'] as String?
        : null),
    emergencyContactPhone:
      json['emergency_contact_phone'] as String? ??
      (contact is Map<String, dynamic>
        ? contact['emergency_contact_phone'] as String?
        : null),
      allergies: _stringList(json['allergies']),
    allergiesSummary:
      json['allergies_summary'] as String? ??
      (summaries is Map<String, dynamic>
        ? summaries['allergies'] as String?
        : null),
      medications: _stringList(json['medications']),
    medicationSummary:
      json['medication_summary'] as String? ??
      (summaries is Map<String, dynamic>
        ? summaries['medications'] as String?
        : null),
      medicalHistory: _stringList(json['medical_history']),
    medicalHistorySummary:
      json['medical_history_summary'] as String? ??
      (summaries is Map<String, dynamic>
        ? summaries['medical_history'] as String?
        : null),
      notes: json['notes'] as String?,
    alerts: alerts,
    hasAlerts: json['has_alerts'] as bool? ?? alerts.isNotEmpty,
      lastVisitAt: _tryParseDate(json['last_visit_at']),
      visitsCount:
          (json['visits_count'] as num?)?.toInt() ??
          ((json['visits'] as List?)?.length ?? 0),
    );
  }
}

class VisitRecord {
  const VisitRecord({
    required this.id,
    required this.patientId,
    this.clinicianId,
    this.noteTemplateId,
    this.encounterType = 'follow_up',
    this.status = 'draft',
    this.chiefComplaint,
    this.conversationSummary,
    this.subjective,
    this.objective,
    this.assessment,
    this.plan,
    this.patientUpdate,
    this.transcript,
    this.privacyNoticeAcknowledgedAt,
    this.recordingConsentObtainedAt,
    this.recordingConsentMethod,
    this.aiTranscriptionConsentObtainedAt,
    this.consentNotes,
    this.templateSnapshot,
    this.meta,
    this.startedAt,
    this.completedAt,
    this.syncedAt,
  });

  final String id;
  final String patientId;
  final int? clinicianId;
  final String? noteTemplateId;
  final String encounterType;
  final String status;
  final String? chiefComplaint;
  final String? conversationSummary;
  final String? subjective;
  final String? objective;
  final String? assessment;
  final String? plan;
  final String? patientUpdate;
  final String? transcript;
  final DateTime? privacyNoticeAcknowledgedAt;
  final DateTime? recordingConsentObtainedAt;
  final String? recordingConsentMethod;
  final DateTime? aiTranscriptionConsentObtainedAt;
  final String? consentNotes;
  final Map<String, dynamic>? templateSnapshot;
  final Map<String, dynamic>? meta;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? syncedAt;

  VisitRecord copyWith({
    String? id,
    String? patientId,
    int? clinicianId,
    String? noteTemplateId,
    String? encounterType,
    String? status,
    String? chiefComplaint,
    String? conversationSummary,
    String? subjective,
    String? objective,
    String? assessment,
    String? plan,
    String? patientUpdate,
    String? transcript,
    DateTime? privacyNoticeAcknowledgedAt,
    DateTime? recordingConsentObtainedAt,
    String? recordingConsentMethod,
    DateTime? aiTranscriptionConsentObtainedAt,
    String? consentNotes,
    Map<String, dynamic>? templateSnapshot,
    Map<String, dynamic>? meta,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? syncedAt,
  }) {
    return VisitRecord(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      clinicianId: clinicianId ?? this.clinicianId,
      noteTemplateId: noteTemplateId ?? this.noteTemplateId,
      encounterType: encounterType ?? this.encounterType,
      status: status ?? this.status,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      conversationSummary: conversationSummary ?? this.conversationSummary,
      subjective: subjective ?? this.subjective,
      objective: objective ?? this.objective,
      assessment: assessment ?? this.assessment,
      plan: plan ?? this.plan,
      patientUpdate: patientUpdate ?? this.patientUpdate,
      transcript: transcript ?? this.transcript,
      privacyNoticeAcknowledgedAt:
          privacyNoticeAcknowledgedAt ?? this.privacyNoticeAcknowledgedAt,
      recordingConsentObtainedAt:
          recordingConsentObtainedAt ?? this.recordingConsentObtainedAt,
      recordingConsentMethod:
          recordingConsentMethod ?? this.recordingConsentMethod,
      aiTranscriptionConsentObtainedAt:
          aiTranscriptionConsentObtainedAt ??
          this.aiTranscriptionConsentObtainedAt,
      consentNotes: consentNotes ?? this.consentNotes,
      templateSnapshot: templateSnapshot ?? this.templateSnapshot,
      meta: meta ?? this.meta,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'clinician_id': clinicianId,
      'note_template_id': noteTemplateId,
      'encounter_type': encounterType,
      'status': status,
      'chief_complaint': chiefComplaint,
      'conversation_summary': conversationSummary,
      'subjective': subjective,
      'objective': objective,
      'assessment': assessment,
      'plan': plan,
      'patient_update': patientUpdate,
      'transcript': transcript,
      'privacy_notice_acknowledged_at': privacyNoticeAcknowledgedAt
          ?.toIso8601String(),
      'recording_consent_obtained_at': recordingConsentObtainedAt
          ?.toIso8601String(),
      'recording_consent_method': recordingConsentMethod,
      'ai_transcription_consent_obtained_at': aiTranscriptionConsentObtainedAt
          ?.toIso8601String(),
      'consent_notes': consentNotes,
      'template_snapshot': templateSnapshot,
      'meta': meta,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
    };
  }

  factory VisitRecord.fromJson(Map<String, dynamic> json) {
    final template = json['template'];
    final templateSnapshot = json['template_snapshot'];
    final consent = json['consent'];

    return VisitRecord(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      clinicianId: (json['clinician_id'] as num?)?.toInt(),
      noteTemplateId:
          json['note_template_id'] as String? ??
          (template is Map<String, dynamic> ? template['id'] as String? : null),
      encounterType: (json['encounter_type'] ?? 'follow_up') as String,
      status: (json['status'] ?? 'draft') as String,
      chiefComplaint: json['chief_complaint'] as String?,
      conversationSummary: json['conversation_summary'] as String?,
      subjective: json['subjective'] as String?,
      objective: json['objective'] as String?,
      assessment: json['assessment'] as String?,
      plan: json['plan'] as String?,
      patientUpdate: json['patient_update'] as String?,
      transcript: json['transcript'] as String?,
      privacyNoticeAcknowledgedAt: _tryParseDate(
        json['privacy_notice_acknowledged_at'] ??
            (consent is Map<String, dynamic>
                ? consent['privacy_notice_acknowledged_at']
                : null),
      ),
      recordingConsentObtainedAt: _tryParseDate(
        json['recording_consent_obtained_at'] ??
            (consent is Map<String, dynamic>
                ? consent['recording_consent_obtained_at']
                : null),
      ),
      recordingConsentMethod:
          json['recording_consent_method'] as String? ??
          (consent is Map<String, dynamic>
              ? consent['recording_consent_method'] as String?
              : null),
      aiTranscriptionConsentObtainedAt: _tryParseDate(
        json['ai_transcription_consent_obtained_at'] ??
            (consent is Map<String, dynamic>
                ? consent['ai_transcription_consent_obtained_at']
                : null),
      ),
      consentNotes:
          json['consent_notes'] as String? ??
          (consent is Map<String, dynamic>
              ? consent['consent_notes'] as String?
              : null),
      templateSnapshot: templateSnapshot is Map<String, dynamic>
          ? Map<String, dynamic>.from(templateSnapshot)
          : template is Map<String, dynamic>
          ? Map<String, dynamic>.from(template)
          : null,
      meta: json['meta'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['meta'] as Map<String, dynamic>)
          : null,
      startedAt: _tryParseDate(json['started_at']),
      completedAt: _tryParseDate(json['completed_at']),
      syncedAt: _tryParseDate(json['synced_at']),
    );
  }
}

class AuthenticatedUser {
  const AuthenticatedUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isApiActive = true,
    this.lastApiLoginAt,
    this.twoFactorEnabled = false,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final bool isApiActive;
  final DateTime? lastApiLoginAt;
  final bool twoFactorEnabled;

  AuthenticatedUser copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    bool? isApiActive,
    DateTime? lastApiLoginAt,
    bool? twoFactorEnabled,
  }) {
    return AuthenticatedUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isApiActive: isApiActive ?? this.isApiActive,
      lastApiLoginAt: lastApiLoginAt ?? this.lastApiLoginAt,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'is_api_active': isApiActive,
      'last_api_login_at': lastApiLoginAt?.toIso8601String(),
      'two_factor_enabled': twoFactorEnabled,
    };
  }

  factory AuthenticatedUser.fromJson(Map<String, dynamic> json) {
    return AuthenticatedUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      role: (json['role'] ?? 'clinician') as String,
      isApiActive: json['is_api_active'] as bool? ?? true,
      lastApiLoginAt: _tryParseDate(json['last_api_login_at']),
      twoFactorEnabled: json['two_factor_enabled'] as bool? ?? false,
    );
  }
}

class SecurityPolicy {
  const SecurityPolicy({
    this.auditLogging = true,
    this.encryptedLocalCacheRequired = true,
    this.recordingRequiresConsent = true,
    this.privacyNoticeVersion,
  });

  final bool auditLogging;
  final bool encryptedLocalCacheRequired;
  final bool recordingRequiresConsent;
  final String? privacyNoticeVersion;

  SecurityPolicy copyWith({
    bool? auditLogging,
    bool? encryptedLocalCacheRequired,
    bool? recordingRequiresConsent,
    String? privacyNoticeVersion,
  }) {
    return SecurityPolicy(
      auditLogging: auditLogging ?? this.auditLogging,
      encryptedLocalCacheRequired:
          encryptedLocalCacheRequired ?? this.encryptedLocalCacheRequired,
      recordingRequiresConsent:
          recordingRequiresConsent ?? this.recordingRequiresConsent,
      privacyNoticeVersion: privacyNoticeVersion ?? this.privacyNoticeVersion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'audit_logging': auditLogging,
      'encrypted_local_cache_required': encryptedLocalCacheRequired,
      'recording_requires_consent': recordingRequiresConsent,
      'privacy_notice_version': privacyNoticeVersion,
    };
  }

  factory SecurityPolicy.fromJson(Map<String, dynamic> json) {
    return SecurityPolicy(
      auditLogging: json['audit_logging'] as bool? ?? true,
      encryptedLocalCacheRequired:
          json['encrypted_local_cache_required'] as bool? ??
          json['local_cache_encryption_required'] as bool? ??
          true,
      recordingRequiresConsent:
          json['recording_requires_consent'] as bool? ?? true,
      privacyNoticeVersion: json['privacy_notice_version'] as String?,
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
    this.security = const SecurityPolicy(),
    this.expiresAt,
  });

  final String token;
  final AuthenticatedUser user;
  final SecurityPolicy security;
  final DateTime? expiresAt;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  AuthSession copyWith({
    String? token,
    AuthenticatedUser? user,
    SecurityPolicy? security,
    DateTime? expiresAt,
  }) {
    return AuthSession(
      token: token ?? this.token,
      user: user ?? this.user,
      security: security ?? this.security,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
      'security': security.toJson(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final user = Map<String, dynamic>.from(
      (json['user'] as Map?) ?? const <String, dynamic>{},
    );
    final security = Map<String, dynamic>.from(
      (json['security'] as Map?) ?? const <String, dynamic>{},
    );

    return AuthSession(
      token: (json['token'] ?? '') as String,
      user: AuthenticatedUser.fromJson(user),
      security: SecurityPolicy.fromJson(security),
      expiresAt: _tryParseDate(json['expires_at']),
    );
  }
}

class NoteTemplateRecord {
  const NoteTemplateRecord({
    required this.id,
    required this.title,
    required this.templateBody,
    this.specialty,
    this.sections = const [],
    this.isSystem = false,
    this.createdBy,
  });

  final String id;
  final String title;
  final String? specialty;
  final String templateBody;
  final List<String> sections;
  final bool isSystem;
  final int? createdBy;

  NoteTemplateRecord copyWith({
    String? id,
    String? title,
    String? specialty,
    String? templateBody,
    List<String>? sections,
    bool? isSystem,
    int? createdBy,
  }) {
    return NoteTemplateRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      specialty: specialty ?? this.specialty,
      templateBody: templateBody ?? this.templateBody,
      sections: sections ?? this.sections,
      isSystem: isSystem ?? this.isSystem,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'specialty': specialty,
      'template_body': templateBody,
      'sections': sections,
      'is_system': isSystem,
      'created_by': createdBy,
    };
  }

  factory NoteTemplateRecord.fromJson(Map<String, dynamic> json) {
    return NoteTemplateRecord(
      id: json['id'] as String,
      title: (json['title'] ?? '') as String,
      specialty: json['specialty'] as String?,
      templateBody: (json['template_body'] ?? '') as String,
      sections: _stringList(json['sections']),
      isSystem: json['is_system'] as bool? ?? false,
      createdBy: (json['created_by'] as num?)?.toInt(),
    );
  }
}

class DictationCapture {
  const DictationCapture({
    required this.id,
    required this.visitId,
    this.mode = 'offline_whisper',
    this.status = 'completed',
    this.locale,
    this.audioPath,
    this.transcript,
    this.summary,
    this.processedOffline = true,
    this.durationSeconds,
    this.meta,
    this.createdAt,
  });

  final String id;
  final String visitId;
  final String mode;
  final String status;
  final String? locale;
  final String? audioPath;
  final String? transcript;
  final String? summary;
  final bool processedOffline;
  final int? durationSeconds;
  final Map<String, dynamic>? meta;
  final DateTime? createdAt;

  DictationCapture copyWith({
    String? id,
    String? visitId,
    String? mode,
    String? status,
    String? locale,
    String? audioPath,
    String? transcript,
    String? summary,
    bool? processedOffline,
    int? durationSeconds,
    Map<String, dynamic>? meta,
    DateTime? createdAt,
  }) {
    return DictationCapture(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      locale: locale ?? this.locale,
      audioPath: audioPath ?? this.audioPath,
      transcript: transcript ?? this.transcript,
      summary: summary ?? this.summary,
      processedOffline: processedOffline ?? this.processedOffline,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      meta: meta ?? this.meta,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visit_id': visitId,
      'mode': mode,
      'status': status,
      'locale': locale,
      'audio_path': audioPath,
      'transcript': transcript,
      'summary': summary,
      'processed_offline': processedOffline,
      'duration_seconds': durationSeconds,
      'meta': meta,
      'append_to_visit': true,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory DictationCapture.fromJson(Map<String, dynamic> json) {
    return DictationCapture(
      id: json['id'] as String,
      visitId: json['visit_id'] as String,
      mode: (json['mode'] ?? 'offline_whisper') as String,
      status: (json['status'] ?? 'completed') as String,
      locale: json['locale'] as String?,
      audioPath: json['audio_path'] as String?,
      transcript: json['transcript'] as String?,
      summary: json['summary'] as String?,
      processedOffline: json['processed_offline'] as bool? ?? true,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      meta: json['meta'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['meta'] as Map<String, dynamic>)
          : null,
      createdAt: _tryParseDate(json['created_at']),
    );
  }
}

class SyncTask {
  const SyncTask({
    required this.key,
    required this.operation,
    required this.entityId,
    required this.payload,
    required this.createdAt,
  });

  final String key;
  final SyncOperation operation;
  final String entityId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  SyncTask copyWith({
    String? key,
    SyncOperation? operation,
    String? entityId,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
  }) {
    return SyncTask(
      key: key ?? this.key,
      operation: operation ?? this.operation,
      entityId: entityId ?? this.entityId,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'operation': operation.name,
      'entity_id': entityId,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SyncTask.fromJson(Map<String, dynamic> json) {
    return SyncTask(
      key: json['key'] as String,
      operation: SyncOperation.values.firstWhere(
        (value) => value.name == json['operation'],
        orElse: () => SyncOperation.upsertPatient,
      ),
      entityId: json['entity_id'] as String,
      payload: Map<String, dynamic>.from(
        (json['payload'] as Map?) ?? const <String, dynamic>{},
      ),
      createdAt: _tryParseDate(json['created_at']) ?? DateTime.now(),
    );
  }
}

class ClinicState {
  const ClinicState({
    this.patients = const [],
    this.visits = const [],
    this.templates = const [],
    this.dictations = const [],
    this.queue = const [],
    this.lastSyncedAt,
    this.syncMessage,
    this.isSyncing = false,
  });

  final List<PatientRecord> patients;
  final List<VisitRecord> visits;
  final List<NoteTemplateRecord> templates;
  final List<DictationCapture> dictations;
  final List<SyncTask> queue;
  final DateTime? lastSyncedAt;
  final String? syncMessage;
  final bool isSyncing;

  ClinicState copyWith({
    List<PatientRecord>? patients,
    List<VisitRecord>? visits,
    List<NoteTemplateRecord>? templates,
    List<DictationCapture>? dictations,
    List<SyncTask>? queue,
    DateTime? lastSyncedAt,
    String? syncMessage,
    bool? isSyncing,
  }) {
    return ClinicState(
      patients: patients ?? this.patients,
      visits: visits ?? this.visits,
      templates: templates ?? this.templates,
      dictations: dictations ?? this.dictations,
      queue: queue ?? this.queue,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncMessage: syncMessage ?? this.syncMessage,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  List<VisitRecord> visitsForPatient(String patientId) {
    final matches = visits
        .where((visit) => visit.patientId == patientId)
        .toList();
    matches.sort(
      (a, b) => (b.startedAt ?? DateTime(1970)).compareTo(
        a.startedAt ?? DateTime(1970),
      ),
    );
    return matches;
  }

  Map<String, dynamic> toJson() {
    return {
      'patients': patients.map((record) => record.toJson()).toList(),
      'visits': visits.map((record) => record.toJson()).toList(),
      'templates': templates.map((record) => record.toJson()).toList(),
      'dictations': dictations.map((record) => record.toJson()).toList(),
      'queue': queue.map((task) => task.toJson()).toList(),
      'last_synced_at': lastSyncedAt?.toIso8601String(),
      'sync_message': syncMessage,
      'is_syncing': isSyncing,
    };
  }

  factory ClinicState.fromJson(Map<String, dynamic> json) {
    return ClinicState(
      patients: _decodeTypedList(json['patients'], PatientRecord.fromJson),
      visits: _decodeTypedList(json['visits'], VisitRecord.fromJson),
      templates: _decodeTypedList(
        json['templates'],
        NoteTemplateRecord.fromJson,
      ),
      dictations: _decodeTypedList(
        json['dictations'],
        DictationCapture.fromJson,
      ),
      queue: _decodeTypedList(json['queue'], SyncTask.fromJson),
      lastSyncedAt: _tryParseDate(json['last_synced_at']),
      syncMessage: json['sync_message'] as String?,
      isSyncing: json['is_syncing'] as bool? ?? false,
    );
  }

  String exportDebugJson() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }
}

DateTime? _tryParseDate(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.tryParse(value.toString());
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }

  return const [];
}

List<T> _decodeTypedList<T>(
  Object? value,
  T Function(Map<String, dynamic> json) builder,
) {
  if (value is! List) {
    return <T>[];
  }

  return value
      .whereType<Map>()
      .map((item) => builder(Map<String, dynamic>.from(item)))
      .toList();
}
