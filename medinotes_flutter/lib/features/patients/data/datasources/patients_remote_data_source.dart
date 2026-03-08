import 'package:dio/dio.dart';

import '../../../../app/repository.dart';
import '../models/patient_api_model.dart';
import '../models/patient_visit_timeline_api_model.dart';
import '../../domain/entities/patient_draft.dart';

class PatientsRemoteDataSource {
  PatientsRemoteDataSource({SessionLocalStore? sessionStore})
    : _sessionStore = sessionStore ?? SessionLocalStore();

  final SessionLocalStore _sessionStore;

  Future<List<PatientApiModel>> fetchPatients() async {
    final dio = await _authorizedClient();
    final response = await dio.get<Map<String, dynamic>>('/patients');
    return _decodeList(response.data?['data'], PatientApiModel.fromJson);
  }

  Future<List<PatientApiModel>> searchPatients(String query) async {
    final dio = await _authorizedClient();
    final response = await dio.get<Map<String, dynamic>>(
      '/patients/search',
      queryParameters: {'query': query},
    );
    return _decodeList(response.data?['data'], PatientApiModel.fromJson);
  }

  Future<PatientApiModel> fetchPatientDetail(String patientId) async {
    final dio = await _authorizedClient();
    final response = await dio.get<Map<String, dynamic>>('/patients/$patientId');
    return PatientApiModel.fromJson(_decodeMap(response.data?['data']));
  }

  Future<PatientApiModel> fetchPatientSummary(String patientId) async {
    final dio = await _authorizedClient();
    final response = await dio.get<Map<String, dynamic>>(
      '/patients/$patientId/summary',
    );
    return PatientApiModel.fromJson(_decodeMap(response.data?['data']));
  }

  Future<List<PatientVisitTimelineApiModel>> fetchPatientTimeline(
    String patientId,
  ) async {
    final dio = await _authorizedClient();
    final response = await dio.get<Map<String, dynamic>>(
      '/patients/$patientId/timeline',
    );
    return _decodeList(
      response.data?['data'],
      (json) => PatientVisitTimelineApiModel.fromJson(patientId, json),
    );
  }

  Future<PatientApiModel> createPatient(PatientDraft draft) async {
    final dio = await _authorizedClient();
    final response = await dio.post<Map<String, dynamic>>(
      '/patients',
      data: _payloadFromDraft(draft),
    );
    return PatientApiModel.fromJson(_decodeMap(response.data?['data']));
  }

  Future<PatientApiModel> updatePatient(
    String patientId,
    PatientDraft draft,
  ) async {
    final dio = await _authorizedClient();
    final response = await dio.put<Map<String, dynamic>>(
      '/patients/$patientId',
      data: _payloadFromDraft(draft),
    );
    return PatientApiModel.fromJson(_decodeMap(response.data?['data']));
  }

  Future<Dio> _authorizedClient() async {
    final session = await _sessionStore.load();
    if (session == null || session.token.trim().isEmpty) {
      throw const ClinicAuthException(
        'Sign in is required before the patient registry can sync.',
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

  Map<String, dynamic> _payloadFromDraft(PatientDraft draft) {
    return {
      'clinic_id': draft.clinicId,
      'medical_record_number': draft.medicalRecordNumber,
      'title': draft.title,
      'first_name': draft.firstName,
      'middle_name': draft.middleName,
      'last_name': draft.lastName,
      'preferred_name': draft.preferredName,
      'date_of_birth': draft.dateOfBirth?.toIso8601String(),
      'sex': draft.sex,
      'phone': draft.phone,
      'alternate_phone': draft.alternatePhone,
      'email': draft.email,
      'national_id_number': draft.nationalIdNumber,
      'passport_number': draft.passportNumber,
      'external_reference': draft.externalReference,
      'address_line_1': draft.addressLine1,
      'address_line_2': draft.addressLine2,
      'city': draft.city,
      'province': draft.province,
      'postal_code': draft.postalCode,
      'country': draft.country,
      'emergency_contact_name': draft.emergencyContactName,
      'emergency_contact_phone': draft.emergencyContactPhone,
      'allergies': draft.allergies,
      'allergies_summary': draft.allergiesSummary,
      'medications': draft.medications,
      'medication_summary': draft.medicationSummary,
      'medical_history': draft.medicalHistory,
      'medical_history_summary': draft.medicalHistorySummary,
      'alerts': draft.alerts,
      'notes': draft.notes,
    }..removeWhere((key, value) => value == null);
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
