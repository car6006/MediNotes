import '../../../patients/domain/entities/patient_draft.dart';

class AppointmentDraft {
  const AppointmentDraft({
    required this.bookingType,
    required this.scheduledFor,
    this.patientId,
    this.newPatient,
    this.providerId,
    this.status = 'booked',
    this.durationMinutes = 30,
    this.reasonForVisit,
    this.notes,
    this.bookingChannel = 'admin_capture',
    this.cancellationReason,
  });

  final String bookingType;
  final String? patientId;
  final PatientDraft? newPatient;
  final String? providerId;
  final String status;
  final DateTime scheduledFor;
  final int durationMinutes;
  final String? reasonForVisit;
  final String? notes;
  final String bookingChannel;
  final String? cancellationReason;

  bool get isNewPatientBooking => bookingType == 'new_patient';
}
