import '../entities/onboarding_form.dart';
import '../entities/onboarding_response.dart';
import '../entities/onboarding_submission.dart';

abstract class OnboardingRepository {
  Future<List<OnboardingForm>> loadForms();

  Future<List<OnboardingResponse>> loadPatientResponses(String patientId);

  Future<OnboardingResponse> submit(OnboardingSubmission submission);
}
