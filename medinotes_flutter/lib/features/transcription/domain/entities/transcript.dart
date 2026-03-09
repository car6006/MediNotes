import '../../../../shared/json_parsing.dart';

class Transcript {
  const Transcript({
    required this.id,
    required this.encounterId,
    required this.transcriptType,
    required this.content,
    this.audioFileId,
    this.sourceEngine,
    this.language,
    this.confidence,
    this.reviewedAt,
    this.meta = const <String, dynamic>{},
    this.audioOriginalFilename,
    this.audioCaptureMode,
    this.audioCapturedAt,
    this.generatedByName,
    this.generatedByEmail,
    this.reviewedByName,
    this.reviewedByEmail,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String encounterId;
  final String? audioFileId;
  final String transcriptType;
  final String? sourceEngine;
  final String content;
  final String? language;
  final double? confidence;
  final DateTime? reviewedAt;
  final Map<String, dynamic> meta;
  final String? audioOriginalFilename;
  final String? audioCaptureMode;
  final DateTime? audioCapturedAt;
  final String? generatedByName;
  final String? generatedByEmail;
  final String? reviewedByName;
  final String? reviewedByEmail;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isRaw => transcriptType == 'raw';
  bool get isCleaned => transcriptType == 'cleaned';

  factory Transcript.fromJson(Map<String, dynamic> json) {
    final audioFile = asMap(json['audio_file']);
    final generatedBy = asMap(json['generated_by']);
    final reviewedBy = asMap(json['reviewed_by']);

    return Transcript(
      id: parseString(json['id']),
      encounterId: parseString(json['encounter_id']),
      audioFileId: parseNullableString(json['audio_file_id']),
      transcriptType: parseString(json['transcript_type']),
      sourceEngine: parseNullableString(json['source_engine']),
      content: parseString(json['content']),
      language: parseNullableString(json['language']),
      confidence: parseDouble(json['confidence']),
      reviewedAt: parseDate(json['reviewed_at']),
      meta: asMap(json['meta']),
      audioOriginalFilename: parseNullableString(audioFile['original_filename']),
      audioCaptureMode: parseNullableString(audioFile['capture_mode']),
      audioCapturedAt: parseDate(audioFile['captured_at']),
      generatedByName: parseNullableString(generatedBy['name']),
      generatedByEmail: parseNullableString(generatedBy['email']),
      reviewedByName: parseNullableString(reviewedBy['name']),
      reviewedByEmail: parseNullableString(reviewedBy['email']),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }
}

class TranscriptDraft {
  const TranscriptDraft({
    required this.transcriptType,
    required this.content,
    this.audioFileId,
    this.sourceEngine,
    this.language,
    this.confidence,
    this.meta = const <String, dynamic>{},
  });

  final String transcriptType;
  final String content;
  final String? audioFileId;
  final String? sourceEngine;
  final String? language;
  final double? confidence;
  final Map<String, dynamic> meta;

  Map<String, dynamic> toPayload() {
    return {
      'audio_file_id': audioFileId,
      'transcript_type': transcriptType,
      'source_engine': sourceEngine,
      'content': content,
      'language': language,
      'confidence': confidence,
      'meta': meta.isEmpty ? null : meta,
    }..removeWhere((key, value) => value == null);
  }
}