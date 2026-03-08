import '../../../../app/models.dart';
import '../../../../app/repository.dart';
import '../models/patient_cache_model.dart';
import '../models/patient_visit_timeline_api_model.dart';

class PatientsLocalDataSource {
  PatientsLocalDataSource({ClinicLocalStore? store})
    : _store = store ?? ClinicLocalStore();

  final ClinicLocalStore _store;

  Future<List<PatientCacheModel>> loadPatients() async {
    final state = await _store.load();
    return state.patients.map(PatientCacheModel.fromRecord).toList();
  }

  Future<PatientCacheModel?> loadPatient(String patientId) async {
    final state = await _store.load();
    PatientRecord? record;
    for (final patient in state.patients) {
      if (patient.id == patientId) {
        record = patient;
        break;
      }
    }

    return record == null ? null : PatientCacheModel.fromRecord(record);
  }

  Future<List<PatientVisitTimelineApiModel>> loadPatientTimeline(
    String patientId,
  ) async {
    final state = await _store.load();
    return state
        .visitsForPatient(patientId)
        .map(PatientVisitTimelineApiModel.fromVisitRecord)
        .toList();
  }

  Future<void> savePatients(Iterable<PatientCacheModel> patients) async {
    final state = await _store.load();
    final nextPatients = [...state.patients];

    for (final patient in patients) {
      _upsert(nextPatients, patient.record, (item) => item.id);
    }

    await _store.save(state.copyWith(patients: nextPatients));
  }

  Future<void> savePatient(PatientCacheModel patient) async {
    await savePatients([patient]);
  }

  Future<void> saveTimeline(
    String patientId,
    Iterable<PatientVisitTimelineApiModel> timeline,
  ) async {
    final state = await _store.load();
    final nextVisits = [...state.visits];
    final timelineList = timeline.toList();

    for (final entry in timelineList) {
      _upsert(nextVisits, entry.toVisitRecord(), (item) => item.id);
    }

    final latestVisitAt = timelineList
        .map((item) => item.startedAt ?? item.completedAt ?? item.syncedAt)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (latest, current) {
          if (latest == null || current.isAfter(latest)) {
            return current;
          }

          return latest;
        });

    final nextPatients = [...state.patients];
    final patientIndex = nextPatients.indexWhere((item) => item.id == patientId);
    if (patientIndex != -1) {
      nextPatients[patientIndex] = nextPatients[patientIndex].copyWith(
        lastVisitAt: latestVisitAt ?? nextPatients[patientIndex].lastVisitAt,
        visitsCount: timelineList.length,
      );
    }

    await _store.save(
      state.copyWith(
        patients: nextPatients,
        visits: nextVisits,
      ),
    );
  }

  void _upsert<T>(List<T> items, T item, String Function(T item) idOf) {
    final index = items.indexWhere((entry) => idOf(entry) == idOf(item));
    if (index == -1) {
      items.add(item);
    } else {
      items[index] = item;
    }
  }
}
