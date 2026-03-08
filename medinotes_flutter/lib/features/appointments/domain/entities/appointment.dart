class Appointment {
  const Appointment({
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

  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';
  bool get isUpcoming => scheduledFor.isAfter(DateTime.now()) && !isCancelled;

  String get patientDisplayName {
    final name = patientName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }

    return patientMedicalRecordNumber?.trim().isNotEmpty == true
        ? patientMedicalRecordNumber!
        : patientId;
  }
}
