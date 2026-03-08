import '../../domain/entities/patient.dart';
import '../../domain/entities/patient_summary.dart';
import '../../domain/entities/patient_visit_timeline_item.dart';

class PatientsState {
  const PatientsState({
    this.patients = const [],
    this.query = '',
    this.selectedPatient,
    this.selectedSummary,
    this.timeline = const [],
    this.isLoadingDetail = false,
    this.isSaving = false,
    this.message,
  });

  final List<Patient> patients;
  final String query;
  final Patient? selectedPatient;
  final PatientSummary? selectedSummary;
  final List<PatientVisitTimelineItem> timeline;
  final bool isLoadingDetail;
  final bool isSaving;
  final String? message;

  static const Object _sentinel = Object();

  PatientsState copyWith({
    List<Patient>? patients,
    String? query,
    Object? selectedPatient = _sentinel,
    Object? selectedSummary = _sentinel,
    List<PatientVisitTimelineItem>? timeline,
    bool? isLoadingDetail,
    bool? isSaving,
    Object? message = _sentinel,
  }) {
    return PatientsState(
      patients: patients ?? this.patients,
      query: query ?? this.query,
      selectedPatient: identical(selectedPatient, _sentinel)
          ? this.selectedPatient
          : selectedPatient as Patient?,
      selectedSummary: identical(selectedSummary, _sentinel)
          ? this.selectedSummary
          : selectedSummary as PatientSummary?,
      timeline: timeline ?? this.timeline,
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
      isSaving: isSaving ?? this.isSaving,
      message: identical(message, _sentinel) ? this.message : message as String?,
    );
  }
}
