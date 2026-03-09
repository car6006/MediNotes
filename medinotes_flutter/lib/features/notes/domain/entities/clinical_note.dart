import '../../../../shared/json_parsing.dart';
import '../../../transcription/domain/entities/transcript.dart';

class ClinicalNote {
  const ClinicalNote({
    required this.id,
    required this.encounterId,
    required this.status,
    required this.noteFormat,
    this.currentVersionId,
    this.currentVersionNumber = 0,
    this.meta = const <String, dynamic>{},
    this.createdByName,
    this.createdByEmail,
    this.signedByName,
    this.signedByEmail,
    this.signedAt,
    this.currentVersion,
    this.versions = const <ClinicalNoteVersion>[],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String encounterId;
  final String status;
  final String noteFormat;
  final String? currentVersionId;
  final int currentVersionNumber;
  final Map<String, dynamic> meta;
  final String? createdByName;
  final String? createdByEmail;
  final String? signedByName;
  final String? signedByEmail;
  final DateTime? signedAt;
  final ClinicalNoteVersion? currentVersion;
  final List<ClinicalNoteVersion> versions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isSignedOff => status == 'signed_off';
  bool get isReviewPending => status == 'doctor_review_pending';

  factory ClinicalNote.fromJson(Map<String, dynamic> json) {
    final createdBy = asMap(json['created_by']);
    final signedBy = asMap(json['signed_by']);
    final currentVersionMap = asMap(json['current_version']);

    return ClinicalNote(
      id: parseString(json['id']),
      encounterId: parseString(json['encounter_id']),
      status: parseString(json['status'], fallback: 'draft'),
      noteFormat: parseString(json['note_format'], fallback: 'soap'),
      currentVersionId: parseNullableString(json['current_version_id']),
      currentVersionNumber: parseInt(json['current_version_number']),
      meta: asMap(json['meta']),
      createdByName: parseNullableString(createdBy['name']),
      createdByEmail: parseNullableString(createdBy['email']),
      signedByName: parseNullableString(signedBy['name']),
      signedByEmail: parseNullableString(signedBy['email']),
      signedAt: parseDate(json['signed_at']),
      currentVersion: currentVersionMap.isEmpty
          ? null
          : ClinicalNoteVersion.fromJson(currentVersionMap),
      versions: asListOfMaps(json['versions'])
          .map(ClinicalNoteVersion.fromJson)
          .toList(),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }
}

class ClinicalNoteVersion {
  const ClinicalNoteVersion({
    required this.id,
    required this.clinicalNoteId,
    required this.encounterId,
    required this.versionNumber,
    required this.source,
    this.sections = const <ClinicalNoteSection>[],
    this.rawTranscriptId,
    this.cleanedTranscriptId,
    this.rawTranscript,
    this.cleanedTranscript,
    this.generatedByName,
    this.generatedByEmail,
    this.signedByName,
    this.signedByEmail,
    this.signedAt,
    this.isLocked = false,
    this.changeSummary,
    this.meta = const <String, dynamic>{},
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String clinicalNoteId;
  final String encounterId;
  final int versionNumber;
  final String source;
  final List<ClinicalNoteSection> sections;
  final String? rawTranscriptId;
  final String? cleanedTranscriptId;
  final Transcript? rawTranscript;
  final Transcript? cleanedTranscript;
  final String? generatedByName;
  final String? generatedByEmail;
  final String? signedByName;
  final String? signedByEmail;
  final DateTime? signedAt;
  final bool isLocked;
  final String? changeSummary;
  final Map<String, dynamic> meta;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ClinicalNoteVersion.fromJson(Map<String, dynamic> json) {
    final generatedBy = asMap(json['generated_by']);
    final signedBy = asMap(json['signed_by']);
    final rawTranscriptMap = asMap(json['raw_transcript']);
    final cleanedTranscriptMap = asMap(json['cleaned_transcript']);

    return ClinicalNoteVersion(
      id: parseString(json['id']),
      clinicalNoteId: parseString(json['clinical_note_id']),
      encounterId: parseString(json['encounter_id']),
      versionNumber: parseInt(json['version_number']),
      source: parseString(json['source'], fallback: 'manual_edit'),
      sections: asListOfMaps(json['sections'])
          .map(ClinicalNoteSection.fromJson)
          .toList(),
      rawTranscriptId: parseNullableString(json['raw_transcript_id']),
      cleanedTranscriptId: parseNullableString(json['cleaned_transcript_id']),
      rawTranscript: rawTranscriptMap.isEmpty
          ? null
          : Transcript.fromJson(rawTranscriptMap),
      cleanedTranscript: cleanedTranscriptMap.isEmpty
          ? null
          : Transcript.fromJson(cleanedTranscriptMap),
      generatedByName: parseNullableString(generatedBy['name']),
      generatedByEmail: parseNullableString(generatedBy['email']),
      signedByName: parseNullableString(signedBy['name']),
      signedByEmail: parseNullableString(signedBy['email']),
      signedAt: parseDate(json['signed_at']),
      isLocked: parseBool(json['is_locked']),
      changeSummary: parseNullableString(json['change_summary']),
      meta: asMap(json['meta']),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }
}

class ClinicalNoteSection {
  const ClinicalNoteSection({
    required this.key,
    required this.label,
    required this.position,
    this.prompt,
    this.isRequired = false,
    this.content,
  });

  final String key;
  final String label;
  final int position;
  final String? prompt;
  final bool isRequired;
  final String? content;

  factory ClinicalNoteSection.fromJson(Map<String, dynamic> json) {
    return ClinicalNoteSection(
      key: parseString(json['key']),
      label: parseString(
        json['label'],
        fallback: parseString(json['key'], fallback: 'Section'),
      ),
      position: parseInt(json['position'], fallback: 1),
      prompt: parseNullableString(json['prompt']),
      isRequired: parseBool(json['is_required']),
      content: parseNullableString(json['content']),
    );
  }
}

class ClinicalNoteDraft {
  const ClinicalNoteDraft({
    required this.sections,
    this.status = 'draft',
    this.changeSummary,
    this.generateWithMedicAI = false,
    this.meta = const <String, dynamic>{},
  });

  final List<ClinicalNoteSectionInput> sections;
  final String status;
  final String? changeSummary;
  final bool generateWithMedicAI;
  final Map<String, dynamic> meta;

  Map<String, dynamic> toPayload() {
    return {
      'status': status,
      'change_summary': changeSummary,
      'generate_with_medicai': generateWithMedicAI,
      'sections': sections.map((section) => section.toPayload()).toList(),
      'meta': meta.isEmpty ? null : meta,
    }..removeWhere((key, value) => value == null);
  }
}

class ClinicalNoteSectionInput {
  const ClinicalNoteSectionInput({
    required this.key,
    required this.label,
    required this.position,
    this.prompt,
    this.isRequired = false,
    this.content,
  });

  final String key;
  final String label;
  final int position;
  final String? prompt;
  final bool isRequired;
  final String? content;

  factory ClinicalNoteSectionInput.fromSection(ClinicalNoteSection section) {
    return ClinicalNoteSectionInput(
      key: section.key,
      label: section.label,
      position: section.position,
      prompt: section.prompt,
      isRequired: section.isRequired,
      content: section.content,
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'key': key,
      'label': label,
      'position': position,
      'prompt': prompt,
      'is_required': isRequired,
      'content': content,
    }..removeWhere((key, value) => value == null);
  }
}