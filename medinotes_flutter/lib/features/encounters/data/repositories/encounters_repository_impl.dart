import '../../../dictation/domain/entities/encounter_audio_file.dart';
import '../../../notes/domain/entities/clinical_note.dart';
import '../../../transcription/domain/entities/transcript.dart';
import '../../domain/entities/encounter.dart';
import '../../domain/repositories/encounters_repository.dart';
import '../datasources/encounters_remote_data_source.dart';

class EncountersRepositoryImpl implements EncountersRepository {
  EncountersRepositoryImpl({EncountersRemoteDataSource? remoteDataSource})
    : _remote = remoteDataSource ?? EncountersRemoteDataSource();

  final EncountersRemoteDataSource _remote;

  @override
  Future<List<Encounter>> loadEncounters({
    String? patientId,
    String? appointmentId,
    String? status,
    int perPage = 50,
  }) {
    return _remote.fetchEncounters(
      patientId: patientId,
      appointmentId: appointmentId,
      status: status,
      perPage: perPage,
    );
  }

  @override
  Future<Encounter> loadEncounter(String encounterId) {
    return _remote.fetchEncounter(encounterId);
  }

  @override
  Future<Encounter> createEncounter(EncounterDraft draft) {
    return _remote.createEncounter(draft);
  }

  @override
  Future<Encounter> updateEncounter(String encounterId, Map<String, dynamic> payload) {
    return _remote.updateEncounter(encounterId, payload);
  }

  @override
  Future<EncounterAudioFile> registerAudio(
    String encounterId,
    EncounterAudioRegistrationDraft draft,
  ) {
    return _remote.registerAudio(encounterId, draft);
  }

  @override
  Future<Transcript> createTranscript(String encounterId, TranscriptDraft draft) {
    return _remote.createTranscript(encounterId, draft);
  }

  @override
  Future<ClinicalNote> createClinicalNote(String encounterId, ClinicalNoteDraft draft) {
    return _remote.createClinicalNote(encounterId, draft);
  }

  @override
  Future<ClinicalNote> updateClinicalNote(String noteId, ClinicalNoteDraft draft) {
    return _remote.updateClinicalNote(noteId, draft);
  }

  @override
  Future<ClinicalNote> signClinicalNote(String noteId, {String? signatureStatement}) {
    return _remote.signClinicalNote(noteId, signatureStatement: signatureStatement);
  }

  @override
  Future<List<ClinicalNoteVersion>> loadClinicalNoteVersions(String noteId) {
    return _remote.fetchClinicalNoteVersions(noteId);
  }
}