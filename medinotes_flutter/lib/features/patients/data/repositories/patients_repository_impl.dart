import '../../domain/entities/patient.dart';
import '../../domain/entities/patient_draft.dart';
import '../../domain/entities/patient_summary.dart';
import '../../domain/entities/patient_visit_timeline_item.dart';
import '../../domain/repositories/patients_repository.dart';
import '../datasources/patients_local_data_source.dart';
import '../datasources/patients_remote_data_source.dart';
import '../models/patient_cache_model.dart';

class PatientsRepositoryImpl implements PatientsRepository {
  PatientsRepositoryImpl({
    PatientsRemoteDataSource? remoteDataSource,
    PatientsLocalDataSource? localDataSource,
  }) : _remote = remoteDataSource ?? PatientsRemoteDataSource(),
       _local = localDataSource ?? PatientsLocalDataSource();

  final PatientsRemoteDataSource _remote;
  final PatientsLocalDataSource _local;

  @override
  Future<List<Patient>> loadPatients({bool refresh = true}) async {
    final cached = (await _local.loadPatients()).map((item) => item.toEntity()).toList();
    if (!refresh) {
      return cached;
    }

    try {
      final remote = await _remote.fetchPatients();
      final patients = remote.map((item) => item.toEntity()).toList();
      await _local.savePatients(
        patients.map(PatientCacheModel.fromEntity),
      );
      return patients;
    } catch (_) {
      return cached;
    }
  }

  @override
  Future<List<Patient>> searchPatients(String query) async {
    final trimmed = query.trim().toLowerCase();
    final cached = (await _local.loadPatients())
        .map((item) => item.toEntity())
        .where((patient) {
          if (trimmed.isEmpty) {
            return true;
          }

          return patient.fullName.toLowerCase().contains(trimmed) ||
              patient.medicalRecordNumber.toLowerCase().contains(trimmed) ||
              (patient.phone ?? '').toLowerCase().contains(trimmed) ||
              (patient.externalReference ?? '').toLowerCase().contains(trimmed);
        })
        .toList();

    if (trimmed.isEmpty) {
      return cached;
    }

    try {
      final remote = await _remote.searchPatients(trimmed);
      final patients = remote.map((item) => item.toEntity()).toList();
      await _local.savePatients(
        patients.map(PatientCacheModel.fromEntity),
      );
      return patients;
    } catch (_) {
      return cached;
    }
  }

  @override
  Future<Patient?> loadPatientDetail(String patientId) async {
    final cached = (await _local.loadPatient(patientId))?.toEntity();

    try {
      final remote = await _remote.fetchPatientDetail(patientId);
      final patient = remote.toEntity();
      await _local.savePatient(PatientCacheModel.fromEntity(patient));
      return patient;
    } catch (_) {
      return cached;
    }
  }

  @override
  Future<PatientSummary?> loadPatientSummary(String patientId) async {
    final cached = (await _local.loadPatient(patientId))?.toEntity();

    try {
      final remote = await _remote.fetchPatientSummary(patientId);
      final patient = remote.toEntity();
      await _local.savePatient(PatientCacheModel.fromEntity(patient));
      return PatientSummary.fromPatient(patient);
    } catch (_) {
      return cached == null ? null : PatientSummary.fromPatient(cached);
    }
  }

  @override
  Future<List<PatientVisitTimelineItem>> loadPatientTimeline(
    String patientId,
  ) async {
    final cached = (await _local.loadPatientTimeline(patientId))
        .map((item) => item.toEntity())
        .toList();

    try {
      final remote = await _remote.fetchPatientTimeline(patientId);
      await _local.saveTimeline(patientId, remote);
      return remote.map((item) => item.toEntity()).toList();
    } catch (_) {
      return cached;
    }
  }

  @override
  Future<Patient> createPatient(PatientDraft draft) async {
    final remote = await _remote.createPatient(draft);
    final patient = remote.toEntity();
    await _local.savePatient(PatientCacheModel.fromEntity(patient));
    return patient;
  }

  @override
  Future<Patient> updatePatient(String patientId, PatientDraft draft) async {
    final remote = await _remote.updatePatient(patientId, draft);
    final patient = remote.toEntity();
    await _local.savePatient(PatientCacheModel.fromEntity(patient));
    return patient;
  }
}
