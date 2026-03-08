import '../../domain/entities/appointment.dart';
import '../../domain/entities/appointment_draft.dart';
import '../../domain/repositories/appointments_repository.dart';
import '../datasources/appointments_remote_data_source.dart';

class AppointmentsRepositoryImpl implements AppointmentsRepository {
  AppointmentsRepositoryImpl({AppointmentsRemoteDataSource? remoteDataSource})
    : _remote = remoteDataSource ?? AppointmentsRemoteDataSource();

  final AppointmentsRemoteDataSource _remote;

  @override
  Future<List<Appointment>> loadAppointments({
    String? patientId,
    String? status,
    DateTime? date,
  }) async {
    final remote = patientId?.trim().isNotEmpty == true &&
            status == null &&
            date == null
        ? await _remote.fetchPatientAppointments(patientId!)
        : await _remote.fetchAppointments(
            patientId: patientId,
            status: status,
            date: date,
          );

    return remote.map((item) => item.toEntity()).toList();
  }

  @override
  Future<Appointment?> loadAppointment(String appointmentId) async {
    try {
      final remote = await _remote.fetchAppointment(appointmentId);
      return remote.toEntity();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Appointment> createAppointment(AppointmentDraft draft) async {
    final remote = await _remote.createAppointment(draft);
    return remote.toEntity();
  }

  @override
  Future<Appointment> updateAppointment(String appointmentId, AppointmentDraft draft) async {
    final remote = await _remote.updateAppointment(appointmentId, draft);
    return remote.toEntity();
  }
}
