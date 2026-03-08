import '../entities/consent_capture_draft.dart';
import '../entities/consent_template.dart';
import '../entities/patient_consent.dart';

abstract class ConsentsRepository {
  Future<List<ConsentTemplate>> loadTemplates();

  Future<List<PatientConsent>> loadPatientConsents(String patientId);

  Future<PatientConsent> captureConsent(ConsentCaptureDraft draft);
}
