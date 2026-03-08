import 'package:dio/dio.dart';

import '../../../../app/repository.dart';
import '../../../patients/domain/entities/patient_draft.dart';
import '../models/appointment_api_model.dart';
import '../../domain/entities/appointment_draft.dart';

class AppointmentsRemoteDataSource {
  AppointmentsRemoteDataSource({SessionLocalStore? sessionStore})
    : _sessionStore = sessionStore ?? SessionLocalStore();

  final SessionLocalStore _sessionStore;

  Future<List<AppointmentApiModel>> fetchAppointments({
    String? patientId,
    String? status,
    DateTime? date,
  }) async {
    final dio = await _authorizedClient();
    final response = await dio.get<Map<String, dynamic>>(
      '/appointments',
      queryParameters: {
        if (patientId?.trim().isNotEmpty ?? false) 'patient_id': patientId,
        if (status?.trim().isNotEmpty ?? false) 'status': status,
        if (date != null) 'date': _dateOnly(date),
      },
    );

    return _decodeList(response.data?['data'], AppointmentApiModel.fromJson);
  }

  Future<List<AppointmentApiModel>> fetchPatientAppointments(String patientId) async {
    final dio = await _authorizedClient();
    final response = await dio.get<Map<String, dynamic>>(
      '/patients/$patientId/appointments',
    );

    return _decodeList(response.data?['data'], AppointmentApiModel.fromJson);
  }

  Future<AppointmentApiModel> fetchAppointment(String appointmentId) async {
    final dio = await _authorizedClient();
    final response = await dio.get<Map<String, dynamic>>('/appointments/$appointmentId');

    return AppointmentApiModel.fromJson(_decodeMap(response.data?['data']));
  }

  Future<AppointmentApiModel> createAppointment(AppointmentDraft draft) async {
    final dio = await _authorizedClient();
    final response = await dio.post<Map<String, dynamic>>(
      '/appointments',
      data: _payloadFromDraft(draft),
    );

    return AppointmentApiModel.fromJson(_decodeMap(response.data?['data']));
  }

  Future<AppointmentApiModel> updateAppointment(
    String appointmentId,
    AppointmentDraft draft,
  ) async {
    final dio = await _authorizedClient();
    final response = await dio.put<Map<String, dynamic>>(
      '/appointments/$appointmentId',
      data: _payloadFromDraft(draft),
    );

    return AppointmentApiModel.fromJson(_decodeMap(response.data?['data']));
  }

  Future<Dio> _authorizedClient() async {
    final session = await _sessionStore.load();
    if (session == null || session.token.trim().isEmpty) {
      throw const ClinicAuthException(
        'Sign in is required before appointments can sync.',
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

  Map<String, dynamic> _payloadFromDraft(AppointmentDraft draft) {
    return {
      'patient_id': draft.patientId,
      'provider_id': draft.providerId,
      'booking_type': draft.bookingType,
      'status': draft.status,
      'scheduled_for': draft.scheduledFor.toIso8601String(),
      'duration_minutes': draft.durationMinutes,
      'reason_for_visit': draft.reasonForVisit,
      'notes': draft.notes,
      'booking_channel': draft.bookingChannel,
      'cancellation_reason': draft.cancellationReason,
      if (draft.newPatient != null) 'patient': _patientPayload(draft.newPatient!),
    }..removeWhere((key, value) => value == null);
  }

  Map<String, dynamic> _patientPayload(PatientDraft draft) {
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

  String _dateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
