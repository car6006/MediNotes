import '../entities/appointment.dart';
import '../entities/appointment_draft.dart';

abstract class AppointmentsRepository {
  Future<List<Appointment>> loadAppointments({
    String? patientId,
    String? status,
    DateTime? date,
  });

  Future<Appointment?> loadAppointment(String appointmentId);

  Future<Appointment> createAppointment(AppointmentDraft draft);

  Future<Appointment> updateAppointment(String appointmentId, AppointmentDraft draft);
}
