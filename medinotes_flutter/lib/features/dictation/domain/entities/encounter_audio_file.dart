import '../../../../shared/json_parsing.dart';

class EncounterAudioFile {
  const EncounterAudioFile({
    required this.id,
    required this.encounterId,
    required this.storagePath,
    this.storageDisk,
    this.originalFilename,
    this.mimeType,
    this.fileSizeBytes,
    this.durationSeconds,
    this.checksumSha256,
    this.captureMode,
    this.capturedAt,
    this.meta = const <String, dynamic>{},
    this.uploadedByName,
    this.uploadedByEmail,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String encounterId;
  final String? storageDisk;
  final String storagePath;
  final String? originalFilename;
  final String? mimeType;
  final int? fileSizeBytes;
  final int? durationSeconds;
  final String? checksumSha256;
  final String? captureMode;
  final DateTime? capturedAt;
  final Map<String, dynamic> meta;
  final String? uploadedByName;
  final String? uploadedByEmail;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory EncounterAudioFile.fromJson(Map<String, dynamic> json) {
    final uploadedBy = asMap(json['uploaded_by']);

    return EncounterAudioFile(
      id: parseString(json['id']),
      encounterId: parseString(json['encounter_id']),
      storageDisk: parseNullableString(json['storage_disk']),
      storagePath: parseString(json['storage_path']),
      originalFilename: parseNullableString(json['original_filename']),
      mimeType: parseNullableString(json['mime_type']),
      fileSizeBytes: json['file_size_bytes'] == null
          ? null
          : parseInt(json['file_size_bytes']),
      durationSeconds: json['duration_seconds'] == null
          ? null
          : parseInt(json['duration_seconds']),
      checksumSha256: parseNullableString(json['checksum_sha256']),
      captureMode: parseNullableString(json['capture_mode']),
      capturedAt: parseDate(json['captured_at']),
      meta: asMap(json['meta']),
      uploadedByName: parseNullableString(uploadedBy['name']),
      uploadedByEmail: parseNullableString(uploadedBy['email']),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }
}

class EncounterAudioRegistrationDraft {
  const EncounterAudioRegistrationDraft({
    required this.storagePath,
    this.storageDisk,
    this.originalFilename,
    this.mimeType,
    this.fileSizeBytes,
    this.durationSeconds,
    this.checksumSha256,
    this.captureMode,
    this.capturedAt,
    this.meta = const <String, dynamic>{},
  });

  final String storagePath;
  final String? storageDisk;
  final String? originalFilename;
  final String? mimeType;
  final int? fileSizeBytes;
  final int? durationSeconds;
  final String? checksumSha256;
  final String? captureMode;
  final DateTime? capturedAt;
  final Map<String, dynamic> meta;

  Map<String, dynamic> toPayload() {
    return {
      'storage_path': storagePath,
      'storage_disk': storageDisk,
      'original_filename': originalFilename,
      'mime_type': mimeType,
      'file_size_bytes': fileSizeBytes,
      'duration_seconds': durationSeconds,
      'checksum_sha256': checksumSha256,
      'capture_mode': captureMode,
      'captured_at': capturedAt?.toIso8601String(),
      'meta': meta.isEmpty ? null : meta,
    }..removeWhere((key, value) => value == null);
  }
}