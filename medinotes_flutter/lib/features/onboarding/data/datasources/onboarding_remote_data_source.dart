import 'package:dio/dio.dart';

import '../../../../app/repository.dart';
import '../../domain/entities/onboarding_submission.dart';
import '../models/onboarding_form_api_model.dart';
import '../models/onboarding_response_api_model.dart';

class OnboardingRemoteDataSource {
  OnboardingRemoteDataSource({SessionLocalStore? sessionStore})
    : _sessionStore = sessionStore ?? SessionLocalStore();

  final SessionLocalStore _sessionStore;

  Future<List<OnboardingFormApiModel>> fetchForms() async {
    final dio = await _authorizedClient();
    final response = await dio.get<Map<String, dynamic>>('/onboarding/forms');
    return _decodeList(response.data?['data'], OnboardingFormApiModel.fromJson);
  }

  Future<List<OnboardingResponseApiModel>> fetchPatientResponses(String patientId) async {
    final dio = await _authorizedClient();
    final response = await dio.get<Map<String, dynamic>>(
      '/patients/$patientId/onboarding',
    );
    return _decodeList(
      response.data?['data'],
      OnboardingResponseApiModel.fromJson,
    );
  }

  Future<OnboardingResponseApiModel> submit(OnboardingSubmission submission) async {
    final dio = await _authorizedClient();
    final response = await dio.post<Map<String, dynamic>>(
      '/onboarding/responses',
      data: {
        'patient_id': submission.patientId,
        'appointment_id': submission.appointmentId,
        'onboarding_form_id': submission.onboardingFormId,
        'source_channel': submission.sourceChannel,
        'responses': submission.responses,
      }..removeWhere((key, value) => value == null),
    );

    return OnboardingResponseApiModel.fromJson(_decodeMap(response.data?['data']));
  }

  Future<Dio> _authorizedClient() async {
    final session = await _sessionStore.load();
    if (session == null || session.token.trim().isEmpty) {
      throw const ClinicAuthException(
        'Sign in is required before onboarding can sync.',
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
