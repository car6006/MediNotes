import 'package:dio/dio.dart';

import '../../../../app/repository.dart';
import '../../../../shared/json_parsing.dart';
import '../../../dictation/domain/entities/encounter_audio_file.dart';
import '../../../notes/domain/entities/clinical_note.dart';
import '../../../transcription/domain/entities/transcript.dart';
import '../../domain/entities/encounter.dart';

class EncountersRemoteDataSource {
  EncountersRemoteDataSource({SessionLocalStore? sessionStore})
    : _sessionStore = sessionStore ?? SessionLocalStore();

  final SessionLocalStore _sessionStore;

  Future<List<Encounter>> fetchEncounters({
    String? patientId,
    String? appointmentId,
    String? status,
    int perPage = 50,
  }) async {
    final dio = await _authorizedClient();
    final response = patientId?.trim().isNotEmpty == true &&
            (appointmentId?.trim().isNotEmpty != true) &&
            (status?.trim().isNotEmpty != true)
        ? await dio.get<Map<String, dynamic>>(
            '/patients/$patientId/encounters',
            queryParameters: {'per_page': perPage},
          )
        : await dio.get<Map<String, dynamic>>(
            '/encounters',
            queryParameters: {
              if (patientId?.trim().isNotEmpty ?? false) 'patient_id': patientId,
              if (appointmentId?.trim().isNotEmpty ?? false)
                'appointment_id': appointmentId,
              if (status?.trim().isNotEmpty ?? false) 'status': status,
              'per_page': perPage,
            },
          );

    return asListOfMaps(response.data?['data']).map(Encounter.fromJson).toList();
  }

  Future<Encounter> fetchEncounter(String encounterId) async {
    final dio = await _authorizedClient();
    final response = await dio.get<Map<String, dynamic>>('/encounters/$encounterId');
    return Encounter.fromJson(asMap(response.data?['data']));
  }

  Future<Encounter> createEncounter(EncounterDraft draft) async {
    final dio = await _authorizedClient();
    final response = await dio.post<Map<String, dynamic>>(
      '/encounters',
      data: draft.toPayload(),
    );

    return Encounter.fromJson(asMap(response.data?['data']));
  }

  Future<Encounter> updateEncounter(String encounterId, Map<String, dynamic> payload) async {
    final dio = await _authorizedClient();
    final response = await dio.patch<Map<String, dynamic>>(
      '/encounters/$encounterId',
      data: payload,
    );

    return Encounter.fromJson(asMap(response.data?['data']));
  }

  Future<EncounterAudioFile> registerAudio(
    String encounterId,
    EncounterAudioRegistrationDraft draft,
  ) async {
    final dio = await _authorizedClient();
    final response = await dio.post<Map<String, dynamic>>(
      '/encounters/$encounterId/audio',
      data: draft.toPayload(),
    );

    return EncounterAudioFile.fromJson(asMap(response.data?['data']));
  }

  Future<Transcript> createTranscript(String encounterId, TranscriptDraft draft) async {
    final dio = await _authorizedClient();
    final response = await dio.post<Map<String, dynamic>>(
      '/encounters/$encounterId/transcripts',
      data: draft.toPayload(),
    );

    return Transcript.fromJson(asMap(response.data?['data']));
  }

  Future<ClinicalNote> createClinicalNote(String encounterId, ClinicalNoteDraft draft) async {
    final dio = await _authorizedClient();
    final response = await dio.post<Map<String, dynamic>>(
      '/encounters/$encounterId/notes',
      data: draft.toPayload(),
    );

    return ClinicalNote.fromJson(asMap(response.data?['data']));
  }

  Future<ClinicalNote> updateClinicalNote(String noteId, ClinicalNoteDraft draft) async {
    final dio = await _authorizedClient();
    final response = await dio.patch<Map<String, dynamic>>(
      '/notes/$noteId',
      data: draft.toPayload(),
    );

    return ClinicalNote.fromJson(asMap(response.data?['data']));
  }

  Future<ClinicalNote> signClinicalNote(String noteId, {String? signatureStatement}) async {
    final dio = await _authorizedClient();
    final response = await dio.post<Map<String, dynamic>>(
      '/notes/$noteId/sign',
      data: {
        if (signatureStatement?.trim().isNotEmpty ?? false)
          'signature_statement': signatureStatement,
      },
    );

    return ClinicalNote.fromJson(asMap(response.data?['data']));
  }

  Future<List<ClinicalNoteVersion>> fetchClinicalNoteVersions(String noteId) async {
    final dio = await _authorizedClient();
    final response = await dio.get<Map<String, dynamic>>('/notes/$noteId/versions');

    return asListOfMaps(response.data?['data'])
        .map(ClinicalNoteVersion.fromJson)
        .toList();
  }

  Future<Dio> _authorizedClient() async {
    final session = await _sessionStore.load();
    if (session == null || session.token.trim().isEmpty) {
      throw const ClinicAuthException(
        'Sign in is required before encounter workflows can sync.',
      );
    }

    return Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.token}',
        },
      ),
    );
  }
}