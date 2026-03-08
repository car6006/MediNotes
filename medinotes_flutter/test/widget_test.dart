import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medinotes_flutter/app/app.dart';
import 'package:medinotes_flutter/app/controller.dart';
import 'package:medinotes_flutter/app/models.dart';
import 'package:medinotes_flutter/app/repository.dart';

void main() {
  testWidgets('clinical shell renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clinicRepositoryProvider.overrideWithValue(
            _FakeClinicRepository(
              localStore: _FakeLocalStore(),
              apiClient: _FakeApiClient(),
            ),
          ),
        ],
        child: const MediNotesApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('MediNotes'), findsWidgets);
    expect(find.text('Clinical command center'), findsOneWidget);
  });
}

class _FakeLocalStore extends ClinicLocalStore {
  @override
  Future<ClinicState> load() async {
    return const ClinicState(
      patients: [
        PatientRecord(
          id: 'patient-1',
          medicalRecordNumber: 'MRN-TEST-0001',
          firstName: 'Test',
          lastName: 'Patient',
          visitsCount: 1,
          medicalHistory: ['Hypertension'],
        ),
      ],
      visits: [
        VisitRecord(
          id: 'visit-1',
          patientId: 'patient-1',
          chiefComplaint: 'Follow-up review',
          status: 'completed',
        ),
      ],
      templates: [
        NoteTemplateRecord(
          id: 'template-1',
          title: 'SOAP',
          templateBody: 'Subjective\nObjective\nAssessment\nPlan',
          sections: ['Subjective', 'Objective', 'Assessment', 'Plan'],
          isSystem: true,
        ),
      ],
    );
  }

  @override
  Future<void> save(ClinicState state) async {}
}

class _FakeApiClient extends ClinicApiClient {
  _FakeApiClient() : super(baseUrl: 'http://localhost');

  @override
  Future<Map<String, dynamic>> fetchBootstrap() async {
    return {
      'data': {
        'patients': [
          {
            'id': 'patient-1',
            'medical_record_number': 'MRN-TEST-0001',
            'first_name': 'Test',
            'last_name': 'Patient',
            'medical_history': ['Hypertension'],
            'visits_count': 1,
          },
        ],
        'visits': [
          {
            'id': 'visit-1',
            'patient_id': 'patient-1',
            'chief_complaint': 'Follow-up review',
            'status': 'completed',
          },
        ],
        'templates': [
          {
            'id': 'template-1',
            'title': 'SOAP',
            'template_body': 'Subjective\nObjective\nAssessment\nPlan',
            'sections': ['Subjective', 'Objective', 'Assessment', 'Plan'],
            'is_system': true,
          },
        ],
      },
    };
  }
}

class _FakeClinicRepository extends ClinicRepository {
  _FakeClinicRepository({required super.localStore, required super.apiClient});

  @override
  Future<AuthSession?> restoreSession() async {
    return const AuthSession(
      token: 'test-token',
      user: AuthenticatedUser(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        role: 'clinician',
      ),
    );
  }

  @override
  Future<AuthSession> refreshSession(AuthSession session) async => session;
}
