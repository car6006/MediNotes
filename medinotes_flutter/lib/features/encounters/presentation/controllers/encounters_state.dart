import '../../../notes/domain/entities/clinical_note.dart';
import '../../domain/entities/encounter.dart';

class EncountersState {
  const EncountersState({
    this.encounters = const <Encounter>[],
    this.selectedEncounter,
    this.noteVersions = const <ClinicalNoteVersion>[],
    this.patientId,
    this.patientName,
    this.appointmentId,
    this.statusFilter,
    this.isLoadingList = false,
    this.isLoadingDetail = false,
    this.isSaving = false,
    this.message,
  });

  final List<Encounter> encounters;
  final Encounter? selectedEncounter;
  final List<ClinicalNoteVersion> noteVersions;
  final String? patientId;
  final String? patientName;
  final String? appointmentId;
  final String? statusFilter;
  final bool isLoadingList;
  final bool isLoadingDetail;
  final bool isSaving;
  final String? message;

  EncountersState copyWith({
    List<Encounter>? encounters,
    Object? selectedEncounter = _sentinel,
    List<ClinicalNoteVersion>? noteVersions,
    Object? patientId = _sentinel,
    Object? patientName = _sentinel,
    Object? appointmentId = _sentinel,
    Object? statusFilter = _sentinel,
    bool? isLoadingList,
    bool? isLoadingDetail,
    bool? isSaving,
    Object? message = _sentinel,
  }) {
    return EncountersState(
      encounters: encounters ?? this.encounters,
      selectedEncounter: identical(selectedEncounter, _sentinel)
          ? this.selectedEncounter
          : selectedEncounter as Encounter?,
      noteVersions: noteVersions ?? this.noteVersions,
      patientId: identical(patientId, _sentinel) ? this.patientId : patientId as String?,
      patientName: identical(patientName, _sentinel)
          ? this.patientName
          : patientName as String?,
      appointmentId: identical(appointmentId, _sentinel)
          ? this.appointmentId
          : appointmentId as String?,
      statusFilter: identical(statusFilter, _sentinel)
          ? this.statusFilter
          : statusFilter as String?,
      isLoadingList: isLoadingList ?? this.isLoadingList,
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
      isSaving: isSaving ?? this.isSaving,
      message: identical(message, _sentinel) ? this.message : message as String?,
    );
  }

  static const Object _sentinel = Object();
}