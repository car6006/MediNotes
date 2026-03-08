import '../../domain/entities/appointment.dart';

class AppointmentApiModel {
  const AppointmentApiModel({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.bookingType,
    required this.status,
    required this.scheduledFor,
    this.providerId,
    this.bookedByUserId,
    this.durationMinutes = 30,
    this.reasonForVisit,
    this.notes,
    this.bookingChannel,
    this.cancellationReason,
    this.metadata = const <String, dynamic>{},
    this.patientName,
    this.patientMedicalRecordNumber,
    this.patientPhone,
    this.providerName,
    this.providerSpecialty,
    this.bookedByName,
    this.confirmedAt,
    this.arrivedAt,
    this.inConsultAt,
    this.completedAt,
    this.cancelledAt,
    this.noShowAt,
    this.onboardingResponsesCount = 0,
    this.consentsCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String clinicId;
  final String patientId;
  final String? providerId;
  final String? bookedByUserId;
  final String bookingType;
  final String status;
  final DateTime scheduledFor;
  final int durationMinutes;
  final String? reasonForVisit;
  final String? notes;
  final String? bookingChannel;
  final String? cancellationReason;
  final Map<String, dynamic> metadata;
  final String? patientName;
  final String? patientMedicalRecordNumber;
  final String? patientPhone;
  final String? providerName;
  final String? providerSpecialty;
  final String? bookedByName;
  final DateTime? confirmedAt;
  final DateTime? arrivedAt;
  final DateTime? inConsultAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? noShowAt;
  final int onboardingResponsesCount;
  final int consentsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Appointment toEntity() {
    return Appointment(
      id: id,
      clinicId: clinicId,
      patientId: patientId,
      providerId: providerId,
      bookedByUserId: bookedByUserId,
      bookingType: bookingType,
      status: status,
      scheduledFor: scheduledFor,
      durationMinutes: durationMinutes,
      reasonForVisit: reasonForVisit,
      notes: notes,
      bookingChannel: bookingChannel,
      cancellationReason: cancellationReason,
      metadata: metadata,
      patientName: patientName,
      patientMedicalRecordNumber: patientMedicalRecordNumber,
      patientPhone: patientPhone,
      providerName: providerName,
      providerSpecialty: providerSpecialty,
      bookedByName: bookedByName,
      confirmedAt: confirmedAt,
      arrivedAt: arrivedAt,
      inConsultAt: inConsultAt,
      completedAt: completedAt,
      cancelledAt: cancelledAt,
      noShowAt: noShowAt,
      onboardingResponsesCount: onboardingResponsesCount,
      consentsCount: consentsCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory AppointmentApiModel.fromJson(Map<String, dynamic> json) {
    final patient = _map(json['patient']);
    final provider = _map(json['provider']);
    final bookedBy = _map(json['booked_by']);
    final timeline = _map(json['timeline']);

    return AppointmentApiModel(
      id: (json['id'] ?? '').toString(),
      clinicId: (json['clinic_id'] ?? '').toString(),
      patientId: (json['patient_id'] ?? '').toString(),
      providerId: json['provider_id'] as String?,
      bookedByUserId: json['booked_by_user_id'] as String?,
      bookingType: (json['booking_type'] ?? 'returning_patient').toString(),
      status: (json['status'] ?? 'booked').toString(),
      scheduledFor: _parseDate(json['scheduled_for']) ?? DateTime.now(),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
      reasonForVisit: json['reason_for_visit'] as String?,
      notes: json['notes'] as String?,
      bookingChannel: json['booking_channel'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      metadata: _map(json['metadata']),
      patientName: patient['full_name'] as String?,
      patientMedicalRecordNumber: patient['medical_record_number'] as String?,
      patientPhone: patient['phone'] as String?,
      providerName: provider['full_name'] as String?,
      providerSpecialty: provider['specialty'] as String?,
      bookedByName: bookedBy['name'] as String?,
      confirmedAt: _parseDate(timeline['confirmed_at']),
      arrivedAt: _parseDate(timeline['arrived_at']),
      inConsultAt: _parseDate(timeline['in_consult_at']),
      completedAt: _parseDate(timeline['completed_at']),
      cancelledAt: _parseDate(timeline['cancelled_at']),
      noShowAt: _parseDate(timeline['no_show_at']),
      onboardingResponsesCount: (json['onboarding_responses_count'] as num?)?.toInt() ?? 0,
      consentsCount: (json['consents_count'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return const <String, dynamic>{};
}

DateTime? _parseDate(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.tryParse(value.toString());
}
