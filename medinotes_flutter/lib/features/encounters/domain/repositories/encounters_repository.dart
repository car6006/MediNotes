import '../../../dictation/domain/entities/encounter_audio_file.dart';
import '../../../notes/domain/entities/clinical_note.dart';
import '../../../transcription/domain/entities/transcript.dart';
import '../entities/encounter.dart';

abstract class EncountersRepository {
  Future<List<Encounter>> loadEncounters({
    String? patientId,
    String? appointmentId,
    String? status,
    int perPage = 50,
  });

  Future<Encounter> loadEncounter(String encounterId);

  Future<Encounter> createEncounter(EncounterDraft draft);

  Future<Encounter> updateEncounter(String encounterId, Map<String, dynamic> payload);

  Future<EncounterAudioFile> registerAudio(
    String encounterId,
    EncounterAudioRegistrationDraft draft,
  );

  Future<Transcript> createTranscript(String encounterId, TranscriptDraft draft);

  Future<ClinicalNote> createClinicalNote(String encounterId, ClinicalNoteDraft draft);

  Future<ClinicalNote> updateClinicalNote(String noteId, ClinicalNoteDraft draft);

  Future<ClinicalNote> signClinicalNote(String noteId, {String? signatureStatement});

  Future<List<ClinicalNoteVersion>> loadClinicalNoteVersions(String noteId);
}