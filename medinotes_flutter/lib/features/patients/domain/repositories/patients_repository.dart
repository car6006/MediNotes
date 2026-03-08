import '../entities/patient.dart';
import '../entities/patient_draft.dart';
import '../entities/patient_summary.dart';
import '../entities/patient_visit_timeline_item.dart';

abstract class PatientsRepository {
  Future<List<Patient>> loadPatients({bool refresh = true});

  Future<List<Patient>> searchPatients(String query);

  Future<Patient?> loadPatientDetail(String patientId);

  Future<PatientSummary?> loadPatientSummary(String patientId);

  Future<List<PatientVisitTimelineItem>> loadPatientTimeline(String patientId);

  Future<Patient> createPatient(PatientDraft draft);

  Future<Patient> updatePatient(String patientId, PatientDraft draft);
}
