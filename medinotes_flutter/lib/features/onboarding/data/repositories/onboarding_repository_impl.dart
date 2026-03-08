import '../../domain/entities/onboarding_form.dart';
import '../../domain/entities/onboarding_response.dart';
import '../../domain/entities/onboarding_submission.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_remote_data_source.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl({OnboardingRemoteDataSource? remoteDataSource})
    : _remote = remoteDataSource ?? OnboardingRemoteDataSource();

  final OnboardingRemoteDataSource _remote;

  @override
  Future<List<OnboardingForm>> loadForms() async {
    final remote = await _remote.fetchForms();
    return remote.map((item) => item.toEntity()).toList();
  }

  @override
  Future<List<OnboardingResponse>> loadPatientResponses(String patientId) async {
    final remote = await _remote.fetchPatientResponses(patientId);
    return remote.map((item) => item.toEntity()).toList();
  }

  @override
  Future<OnboardingResponse> submit(OnboardingSubmission submission) async {
    final remote = await _remote.submit(submission);
    return remote.toEntity();
  }
}
