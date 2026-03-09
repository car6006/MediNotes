import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dictation/domain/entities/encounter_audio_file.dart';
import '../../../notes/domain/entities/clinical_note.dart';
import '../../../transcription/domain/entities/transcript.dart';
import '../../data/repositories/encounters_repository_impl.dart';
import '../../domain/entities/encounter.dart';
import '../../domain/repositories/encounters_repository.dart';
import 'encounters_state.dart';

final encountersRepositoryProvider = Provider<EncountersRepository>((ref) {
  return EncountersRepositoryImpl();
});

final encountersControllerProvider = AsyncNotifierProvider<EncountersController, EncountersState>(
  EncountersController.new,
);

class EncountersController extends AsyncNotifier<EncountersState> {
  late final EncountersRepository _repository;

  @override
  FutureOr<EncountersState> build() {
    _repository = ref.read(encountersRepositoryProvider);
    return const EncountersState();
  }

  Future<void> load({
    String? patientId,
    String? patientName,
    String? appointmentId,
    String? status,
  }) async {
    final current = state.valueOrNull ?? const EncountersState();
    state = AsyncValue.data(
      current.copyWith(
        patientId: patientId,
        patientName: patientName,
        appointmentId: appointmentId,
        statusFilter: status,
        isLoadingList: true,
        message: 'Loading encounters...',
      ),
    );

    final encounters = await _repository.loadEncounters(
      patientId: patientId,
      appointmentId: appointmentId,
      status: status,
    );

    final selected = current.selectedEncounter == null
        ? null
        : encounters.cast<Encounter?>().firstWhere(
            (item) => item?.id == current.selectedEncounter?.id,
            orElse: () => current.selectedEncounter,
          );

    state = AsyncValue.data(
      current.copyWith(
        encounters: encounters,
        selectedEncounter: selected,
        isLoadingList: false,
        message: encounters.isEmpty
            ? 'No encounters matched the current filters.'
            : 'Encounters loaded.',
      ),
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull ?? const EncountersState();
    await load(
      patientId: current.patientId,
      patientName: current.patientName,
      appointmentId: current.appointmentId,
      status: current.statusFilter,
    );
  }

  Future<Encounter> openEncounter(String encounterId) async {
    final current = state.valueOrNull ?? const EncountersState();
    state = AsyncValue.data(
      current.copyWith(
        isLoadingDetail: true,
        noteVersions: const <ClinicalNoteVersion>[],
        message: 'Loading encounter details...',
      ),
    );

    final encounter = await _repository.loadEncounter(encounterId);
    final updatedEncounters = _upsertEncounter(current.encounters, encounter);

    state = AsyncValue.data(
      current.copyWith(
        encounters: updatedEncounters,
        selectedEncounter: encounter,
        noteVersions: encounter.currentClinicalNote?.versions ?? const <ClinicalNoteVersion>[],
        isLoadingDetail: false,
        message: 'Encounter details loaded.',
      ),
    );

    return encounter;
  }

  Future<Encounter> startEncounter(EncounterDraft draft) async {
    final current = state.valueOrNull ?? const EncountersState();
    state = AsyncValue.data(current.copyWith(isSaving: true, message: 'Starting encounter...'));

    final encounter = await _repository.createEncounter(draft);
    final refreshedList = await _repository.loadEncounters(
      patientId: current.patientId ?? draft.patientId,
      appointmentId: current.appointmentId ?? draft.appointmentId,
      status: current.statusFilter,
    );
    final detail = await _repository.loadEncounter(encounter.id);

    state = AsyncValue.data(
      current.copyWith(
        encounters: _upsertEncounter(refreshedList, detail),
        selectedEncounter: detail,
        noteVersions: detail.currentClinicalNote?.versions ?? const <ClinicalNoteVersion>[],
        patientId: current.patientId ?? draft.patientId,
        appointmentId: current.appointmentId ?? draft.appointmentId,
        isSaving: false,
        message: 'Encounter started.',
      ),
    );

    return detail;
  }

  Future<Encounter> updateEncounterStatus(String encounterId, String status) async {
    final current = state.valueOrNull ?? const EncountersState();
    state = AsyncValue.data(current.copyWith(isSaving: true, message: 'Updating encounter status...'));

    await _repository.updateEncounter(encounterId, {'status': status});
    final encounter = await _repository.loadEncounter(encounterId);

    state = AsyncValue.data(
      current.copyWith(
        encounters: _upsertEncounter(current.encounters, encounter),
        selectedEncounter: encounter,
        noteVersions: encounter.currentClinicalNote?.versions ?? current.noteVersions,
        isSaving: false,
        message: 'Encounter updated.',
      ),
    );

    return encounter;
  }

  Future<EncounterAudioFile> registerAudio(
    String encounterId,
    EncounterAudioRegistrationDraft draft,
  ) async {
    final current = state.valueOrNull ?? const EncountersState();
    state = AsyncValue.data(current.copyWith(isSaving: true, message: 'Registering encounter audio...'));

    final audioFile = await _repository.registerAudio(encounterId, draft);
    await _refreshEncounter(encounterId, message: 'Encounter audio saved.');

    return audioFile;
  }

  Future<Transcript> saveTranscript(String encounterId, TranscriptDraft draft) async {
    final current = state.valueOrNull ?? const EncountersState();
    state = AsyncValue.data(current.copyWith(isSaving: true, message: 'Saving transcript...'));

    final transcript = await _repository.createTranscript(encounterId, draft);
    await _refreshEncounter(encounterId, message: 'Transcript saved.');

    return transcript;
  }

  Future<ClinicalNote> createClinicalNote(String encounterId, ClinicalNoteDraft draft) async {
    final current = state.valueOrNull ?? const EncountersState();
    state = AsyncValue.data(current.copyWith(isSaving: true, message: 'Creating clinical note...'));

    final note = await _repository.createClinicalNote(encounterId, draft);
    await _refreshEncounter(encounterId, message: 'Clinical note created.');
    await loadNoteVersions(note.id);

    return note;
  }

  Future<ClinicalNote> updateClinicalNote(
    String encounterId,
    String noteId,
    ClinicalNoteDraft draft,
  ) async {
    final current = state.valueOrNull ?? const EncountersState();
    state = AsyncValue.data(current.copyWith(isSaving: true, message: 'Saving clinical note...'));

    final note = await _repository.updateClinicalNote(noteId, draft);
    await _refreshEncounter(encounterId, message: 'Clinical note updated.');
    await loadNoteVersions(note.id);

    return note;
  }

  Future<ClinicalNote> signClinicalNote(
    String encounterId,
    String noteId, {
    String? signatureStatement,
  }) async {
    final current = state.valueOrNull ?? const EncountersState();
    state = AsyncValue.data(current.copyWith(isSaving: true, message: 'Signing clinical note...'));

    final note = await _repository.signClinicalNote(
      noteId,
      signatureStatement: signatureStatement,
    );
    await _refreshEncounter(encounterId, message: 'Clinical note signed off.');
    await loadNoteVersions(note.id);

    return note;
  }

  Future<List<ClinicalNoteVersion>> loadNoteVersions(String noteId) async {
    final current = state.valueOrNull ?? const EncountersState();
    state = AsyncValue.data(current.copyWith(isLoadingDetail: true, message: 'Loading note versions...'));

    final versions = await _repository.loadClinicalNoteVersions(noteId);

    state = AsyncValue.data(
      current.copyWith(
        noteVersions: versions,
        isLoadingDetail: false,
        message: versions.isEmpty ? 'No note versions available.' : 'Note versions loaded.',
      ),
    );

    return versions;
  }

  void clearNoteVersions() {
    final current = state.valueOrNull ?? const EncountersState();
    state = AsyncValue.data(current.copyWith(noteVersions: const <ClinicalNoteVersion>[]));
  }

  Future<Encounter> _refreshEncounter(String encounterId, {String? message}) async {
    final current = state.valueOrNull ?? const EncountersState();
    final encounter = await _repository.loadEncounter(encounterId);

    state = AsyncValue.data(
      current.copyWith(
        encounters: _upsertEncounter(current.encounters, encounter),
        selectedEncounter: encounter,
        noteVersions: encounter.currentClinicalNote?.versions ?? current.noteVersions,
        isSaving: false,
        isLoadingDetail: false,
        message: message,
      ),
    );

    return encounter;
  }

  List<Encounter> _upsertEncounter(List<Encounter> encounters, Encounter encounter) {
    final next = <Encounter>[...encounters];
    final index = next.indexWhere((item) => item.id == encounter.id);

    if (index == -1) {
      if (_matchesActiveFilters(encounter)) {
        next.insert(0, encounter);
      }
      return next;
    }

    next[index] = encounter;
    return next;
  }

  bool _matchesActiveFilters(Encounter encounter) {
    final current = state.valueOrNull ?? const EncountersState();
    if (current.patientId?.trim().isNotEmpty == true && encounter.patientId != current.patientId) {
      return false;
    }

    if (current.appointmentId?.trim().isNotEmpty == true && encounter.appointmentId != current.appointmentId) {
      return false;
    }

    if (current.statusFilter?.trim().isNotEmpty == true && encounter.status != current.statusFilter) {
      return false;
    }

    return true;
  }
}