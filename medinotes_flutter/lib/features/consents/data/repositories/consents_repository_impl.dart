import '../../domain/entities/consent_capture_draft.dart';
import '../../domain/entities/consent_template.dart';
import '../../domain/entities/patient_consent.dart';
import '../../domain/repositories/consents_repository.dart';
import '../datasources/consents_remote_data_source.dart';

class ConsentsRepositoryImpl implements ConsentsRepository {
  ConsentsRepositoryImpl({ConsentsRemoteDataSource? remoteDataSource})
    : _remote = remoteDataSource ?? ConsentsRemoteDataSource();

  final ConsentsRemoteDataSource _remote;

  @override
  Future<List<ConsentTemplate>> loadTemplates() async {
    final remote = await _remote.fetchTemplates();
    return remote.map((item) => item.toEntity()).toList();
  }

  @override
  Future<List<PatientConsent>> loadPatientConsents(String patientId) async {
    final remote = await _remote.fetchPatientConsents(patientId);
    return remote.map((item) => item.toEntity()).toList();
  }

  @override
  Future<PatientConsent> captureConsent(ConsentCaptureDraft draft) async {
    final remote = await _remote.captureConsent(draft);
    return remote.toEntity();
  }
}
