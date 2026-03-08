import 'package:dio/dio.dart';

import '../../../../app/repository.dart';
import '../../domain/entities/consent_capture_draft.dart';
import '../models/consent_template_api_model.dart';
import '../models/patient_consent_api_model.dart';

class ConsentsRemoteDataSource {
  ConsentsRemoteDataSource({SessionLocalStore? sessionStore})
    : _sessionStore = sessionStore ?? SessionLocalStore();

  final SessionLocalStore _sessionStore;

  Future<List<ConsentTemplateApiModel>> fetchTemplates() async {
    final dio = await _authorizedClient();
    final response = await dio.get<Map<String, dynamic>>('/consent-templates');
    return _decodeList(response.data?['data'], ConsentTemplateApiModel.fromJson);
  }

  Future<List<PatientConsentApiModel>> fetchPatientConsents(String patientId) async {
    final dio = await _authorizedClient();
    final response = await dio.get<Map<String, dynamic>>(
      '/patients/$patientId/consents',
    );
    return _decodeList(response.data?['data'], PatientConsentApiModel.fromJson);
  }

  Future<PatientConsentApiModel> captureConsent(ConsentCaptureDraft draft) async {
    final dio = await _authorizedClient();
    final response = await dio.post<Map<String, dynamic>>(
      '/consents',
      data: {
        'patient_id': draft.patientId,
        'appointment_id': draft.appointmentId,
        'consent_template_id': draft.consentTemplateId,
        'accepted_by': draft.acceptedBy,
        'source_channel': draft.sourceChannel,
        'accepted_payload': draft.acceptedPayload,
        'notes': draft.notes,
      }..removeWhere((key, value) => value == null),
    );

    return PatientConsentApiModel.fromJson(_decodeMap(response.data?['data']));
  }

  Future<Dio> _authorizedClient() async {
    final session = await _sessionStore.load();
    if (session == null || session.token.trim().isEmpty) {
      throw const ClinicAuthException(
        'Sign in is required before consents can sync.',
      );
    }

    return Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.token}',
        },
      ),
    );
  }

  Map<String, dynamic> _decodeMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return const <String, dynamic>{};
  }

  List<T> _decodeList<T>(
    Object? value,
    T Function(Map<String, dynamic> json) builder,
  ) {
    if (value is! List) {
      return <T>[];
    }

    return value
        .whereType<Map>()
        .map((item) => builder(Map<String, dynamic>.from(item)))
        .toList();
  }
}
