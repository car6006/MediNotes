import '../../../../shared/json_parsing.dart';
import '../../../dictation/domain/entities/encounter_audio_file.dart';
import '../../../notes/domain/entities/clinical_note.dart';
import '../../../transcription/domain/entities/transcript.dart';

class Encounter {
  const Encounter({
    required this.id,
    required this.patientId,
    required this.status,
    this.clinicId,
    this.appointmentId,
    this.providerId,
    this.clinicianId,
    this.encounterTemplateId,
    this.encounterType,
    this.chiefComplaint,
    this.patient,
    this.provider,
    this.appointment,
    this.template,
    this.counts = const EncounterCounts(),
    this.consent = const EncounterConsent(),
    this.timeline = const EncounterTimeline(),
    this.currentClinicalNote,
    this.audioFiles = const <EncounterAudioFile>[],
    this.transcripts = const <Transcript>[],
    this.compatibilityNote = const EncounterCompatibilityNote(),
    this.templateSnapshot = const <String, dynamic>{},
    this.meta = const <String, dynamic>{},
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? clinicId;
  final String patientId;
  final String? appointmentId;
  final String? providerId;
  final String? clinicianId;
  final String? encounterTemplateId;
  final String? encounterType;
  final String status;
  final String? chiefComplaint;
  final EncounterPatientInfo? patient;
  final EncounterProviderInfo? provider;
  final EncounterAppointmentInfo? appointment;
  final EncounterTemplateInfo? template;
  final EncounterCounts counts;
  final EncounterConsent consent;
  final EncounterTimeline timeline;
  final ClinicalNote? currentClinicalNote;
  final List<EncounterAudioFile> audioFiles;
  final List<Transcript> transcripts;
  final EncounterCompatibilityNote compatibilityNote;
  final Map<String, dynamic> templateSnapshot;
  final Map<String, dynamic> meta;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
  bool get canComplete => currentClinicalNote?.isSignedOff == true;

  factory Encounter.fromJson(Map<String, dynamic> json) {
    final patient = asMap(json['patient']);
    final provider = asMap(json['provider']);
    final appointment = asMap(json['appointment']);
    final template = asMap(json['encounter_template']);
    final currentClinicalNote = asMap(json['current_clinical_note']);

    return Encounter(
      id: parseString(json['id']),
      clinicId: parseNullableString(json['clinic_id']),
      patientId: parseString(json['patient_id']),
      appointmentId: parseNullableString(json['appointment_id']),
      providerId: parseNullableString(json['provider_id']),
      clinicianId: parseNullableString(json['clinician_id']),
      encounterTemplateId: parseNullableString(json['encounter_template_id']),
      encounterType: parseNullableString(json['encounter_type']),
      status: parseString(json['status'], fallback: 'created'),
      chiefComplaint: parseNullableString(json['chief_complaint']),
      patient: patient.isEmpty ? null : EncounterPatientInfo.fromJson(patient),
      provider: provider.isEmpty
          ? null
          : EncounterProviderInfo.fromJson(provider),
      appointment: appointment.isEmpty
          ? null
          : EncounterAppointmentInfo.fromJson(appointment),
      template: template.isEmpty ? null : EncounterTemplateInfo.fromJson(template),
      counts: EncounterCounts.fromJson(asMap(json['counts'])),
      consent: EncounterConsent.fromJson(asMap(json['consent'])),
      timeline: EncounterTimeline.fromJson(asMap(json['timeline'])),
      currentClinicalNote: currentClinicalNote.isEmpty
          ? null
          : ClinicalNote.fromJson(currentClinicalNote),
      audioFiles: asListOfMaps(json['audio_files'])
          .map(EncounterAudioFile.fromJson)
          .toList(),
      transcripts: asListOfMaps(json['transcripts'])
          .map(Transcript.fromJson)
          .toList(),
      compatibilityNote: EncounterCompatibilityNote.fromJson(
        asMap(json['compatibility_note']),
      ),
      templateSnapshot: asMap(json['template_snapshot']),
      meta: asMap(json['meta']),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }
}

class EncounterPatientInfo {
  const EncounterPatientInfo({
    required this.id,
    this.fullName,
    this.preferredName,
    this.medicalRecordNumber,
    this.phone,
    this.email,
    this.hasAlerts = false,
    this.alerts = const <String>[],
  });

  final String id;
  final String? fullName;
  final String? preferredName;
  final String? medicalRecordNumber;
  final String? phone;
  final String? email;
  final bool hasAlerts;
  final List<String> alerts;

  factory EncounterPatientInfo.fromJson(Map<String, dynamic> json) {
    final alerts = asStringList(json['alerts']);

    return EncounterPatientInfo(
      id: parseString(json['id']),
      fullName: parseNullableString(json['full_name']),
      preferredName: parseNullableString(json['preferred_name']),
      medicalRecordNumber: parseNullableString(json['medical_record_number']),
      phone: parseNullableString(json['phone']),
      email: parseNullableString(json['email']),
      hasAlerts: parseBool(json['has_alerts'], fallback: alerts.isNotEmpty),
      alerts: alerts,
    );
  }
}

class EncounterProviderInfo {
  const EncounterProviderInfo({
    required this.id,
    this.fullName,
    this.specialty,
  });

  final String id;
  final String? fullName;
  final String? specialty;

  factory EncounterProviderInfo.fromJson(Map<String, dynamic> json) {
    return EncounterProviderInfo(
      id: parseString(json['id']),
      fullName: parseNullableString(json['full_name']),
      specialty: parseNullableString(json['specialty']),
    );
  }
}

class EncounterAppointmentInfo {
  const EncounterAppointmentInfo({
    required this.id,
    this.status,
    this.scheduledFor,
  });

  final String id;
  final String? status;
  final DateTime? scheduledFor;

  factory EncounterAppointmentInfo.fromJson(Map<String, dynamic> json) {
    return EncounterAppointmentInfo(
      id: parseString(json['id']),
      status: parseNullableString(json['status']),
      scheduledFor: parseDate(json['scheduled_for']),
    );
  }
}

class EncounterTemplateInfo {
  const EncounterTemplateInfo({
    required this.id,
    this.title,
    this.version,
    this.specialty,
    this.noteFormat,
    this.sections = const <String>[],
  });

  final String id;
  final String? title;
  final String? version;
  final String? specialty;
  final String? noteFormat;
  final List<String> sections;

  factory EncounterTemplateInfo.fromJson(Map<String, dynamic> json) {
    return EncounterTemplateInfo(
      id: parseString(json['id']),
      title: parseNullableString(json['title']),
      version: parseNullableString(json['version']),
      specialty: parseNullableString(json['specialty']),
      noteFormat: parseNullableString(json['note_format']),
      sections: asStringList(json['sections']),
    );
  }
}

class EncounterCounts {
  const EncounterCounts({
    this.audioFiles = 0,
    this.transcripts = 0,
  });

  final int audioFiles;
  final int transcripts;

  factory EncounterCounts.fromJson(Map<String, dynamic> json) {
    return EncounterCounts(
      audioFiles: parseInt(json['audio_files']),
      transcripts: parseInt(json['transcripts']),
    );
  }
}

class EncounterConsent {
  const EncounterConsent({
    this.privacyNoticeAcknowledgedAt,
    this.recordingConsentObtainedAt,
    this.recordingConsentMethod,
    this.aiTranscriptionConsentObtainedAt,
    this.consentNotes,
  });

  final DateTime? privacyNoticeAcknowledgedAt;
  final DateTime? recordingConsentObtainedAt;
  final String? recordingConsentMethod;
  final DateTime? aiTranscriptionConsentObtainedAt;
  final String? consentNotes;

  bool get hasRecordingConsent =>
      privacyNoticeAcknowledgedAt != null &&
      recordingConsentObtainedAt != null &&
      (recordingConsentMethod?.trim().isNotEmpty ?? false);

  bool get hasAiConsent => aiTranscriptionConsentObtainedAt != null;

  factory EncounterConsent.fromJson(Map<String, dynamic> json) {
    return EncounterConsent(
      privacyNoticeAcknowledgedAt: parseDate(
        json['privacy_notice_acknowledged_at'],
      ),
      recordingConsentObtainedAt: parseDate(
        json['recording_consent_obtained_at'],
      ),
      recordingConsentMethod: parseNullableString(
        json['recording_consent_method'],
      ),
      aiTranscriptionConsentObtainedAt: parseDate(
        json['ai_transcription_consent_obtained_at'],
      ),
      consentNotes: parseNullableString(json['consent_notes']),
    );
  }
}

class EncounterTimeline {
  const EncounterTimeline({
    this.statusChangedAt,
    this.startedAt,
    this.inProgressAt,
    this.dictationCapturedAt,
    this.transcriptionPendingAt,
    this.draftNoteReadyAt,
    this.doctorReviewPendingAt,
    this.signedOffAt,
    this.completedAt,
    this.syncedAt,
  });

  final DateTime? statusChangedAt;
  final DateTime? startedAt;
  final DateTime? inProgressAt;
  final DateTime? dictationCapturedAt;
  final DateTime? transcriptionPendingAt;
  final DateTime? draftNoteReadyAt;
  final DateTime? doctorReviewPendingAt;
  final DateTime? signedOffAt;
  final DateTime? completedAt;
  final DateTime? syncedAt;

  factory EncounterTimeline.fromJson(Map<String, dynamic> json) {
    return EncounterTimeline(
      statusChangedAt: parseDate(json['status_changed_at']),
      startedAt: parseDate(json['started_at']),
      inProgressAt: parseDate(json['in_progress_at']),
      dictationCapturedAt: parseDate(json['dictation_captured_at']),
      transcriptionPendingAt: parseDate(json['transcription_pending_at']),
      draftNoteReadyAt: parseDate(json['draft_note_ready_at']),
      doctorReviewPendingAt: parseDate(json['doctor_review_pending_at']),
      signedOffAt: parseDate(json['signed_off_at']),
      completedAt: parseDate(json['completed_at']),
      syncedAt: parseDate(json['synced_at']),
    );
  }
}

class EncounterCompatibilityNote {
  const EncounterCompatibilityNote({
    this.conversationSummary,
    this.subjective,
    this.objective,
    this.assessment,
    this.plan,
    this.patientUpdate,
    this.transcript,
  });

  final String? conversationSummary;
  final String? subjective;
  final String? objective;
  final String? assessment;
  final String? plan;
  final String? patientUpdate;
  final String? transcript;

  factory EncounterCompatibilityNote.fromJson(Map<String, dynamic> json) {
    return EncounterCompatibilityNote(
      conversationSummary: parseNullableString(json['conversation_summary']),
      subjective: parseNullableString(json['subjective']),
      objective: parseNullableString(json['objective']),
      assessment: parseNullableString(json['assessment']),
      plan: parseNullableString(json['plan']),
      patientUpdate: parseNullableString(json['patient_update']),
      transcript: parseNullableString(json['transcript']),
    );
  }
}

class EncounterDraft {
  const EncounterDraft({
    this.clinicId,
    this.patientId,
    this.appointmentId,
    this.providerId,
    this.encounterTemplateId,
    this.encounterType,
    this.chiefComplaint,
    this.privacyNoticeAcknowledgedAt,
    this.recordingConsentObtainedAt,
    this.recordingConsentMethod,
    this.aiTranscriptionConsentObtainedAt,
    this.consentNotes,
    this.meta = const <String, dynamic>{},
    this.startedAt,
  });

  final String? clinicId;
  final String? patientId;
  final String? appointmentId;
  final String? providerId;
  final String? encounterTemplateId;
  final String? encounterType;
  final String? chiefComplaint;
  final DateTime? privacyNoticeAcknowledgedAt;
  final DateTime? recordingConsentObtainedAt;
  final String? recordingConsentMethod;
  final DateTime? aiTranscriptionConsentObtainedAt;
  final String? consentNotes;
  final Map<String, dynamic> meta;
  final DateTime? startedAt;

  Map<String, dynamic> toPayload() {
    return {
      'clinic_id': clinicId,
      'patient_id': patientId,
      'appointment_id': appointmentId,
      'provider_id': providerId,
      'encounter_template_id': encounterTemplateId,
      'encounter_type': encounterType,
      'chief_complaint': chiefComplaint,
      'privacy_notice_acknowledged_at': privacyNoticeAcknowledgedAt?.toIso8601String(),
      'recording_consent_obtained_at': recordingConsentObtainedAt?.toIso8601String(),
      'recording_consent_method': recordingConsentMethod,
      'ai_transcription_consent_obtained_at': aiTranscriptionConsentObtainedAt?.toIso8601String(),
      'consent_notes': consentNotes,
      'meta': meta.isEmpty ? null : meta,
      'started_at': startedAt?.toIso8601String(),
    }..removeWhere((key, value) => value == null);
  }
}