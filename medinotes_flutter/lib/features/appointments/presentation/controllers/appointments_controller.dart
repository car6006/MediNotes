import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/appointments_repository_impl.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/appointment_draft.dart';
import '../../domain/repositories/appointments_repository.dart';
import 'appointments_state.dart';

final appointmentsRepositoryProvider = Provider<AppointmentsRepository>((ref) {
  return AppointmentsRepositoryImpl();
});

final appointmentsControllerProvider =
    AsyncNotifierProvider<AppointmentsController, AppointmentsState>(
      AppointmentsController.new,
    );

class AppointmentsController extends AsyncNotifier<AppointmentsState> {
  late final AppointmentsRepository _repository;

  @override
  Future<AppointmentsState> build() async {
    _repository = ref.read(appointmentsRepositoryProvider);
    final appointments = await _repository.loadAppointments();

    return AppointmentsState(
      appointments: appointments,
      message: appointments.isEmpty
          ? 'No appointments found for the current filters.'
          : 'Appointments loaded.',
    );
  }

  Future<void> load({String? patientId, String? status, DateTime? date}) async {
    final current = state.valueOrNull ?? const AppointmentsState();
    state = AsyncValue.data(
      current.copyWith(
        patientId: patientId,
        statusFilter: status,
        dateFilter: date,
        message: 'Loading appointments...',
      ),
    );

    final appointments = await _repository.loadAppointments(
      patientId: patientId,
      status: status,
      date: date,
    );

    state = AsyncValue.data(
      current.copyWith(
        appointments: appointments,
        patientId: patientId,
        statusFilter: status,
        dateFilter: date,
        message: appointments.isEmpty
            ? 'No appointments matched the current filters.'
            : 'Appointments refreshed.',
      ),
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull ?? const AppointmentsState();
    await load(
      patientId: current.patientId,
      status: current.statusFilter,
      date: current.dateFilter,
    );
  }

  Future<Appointment> createAppointment(AppointmentDraft draft) async {
    final current = state.valueOrNull ?? const AppointmentsState();
    state = AsyncValue.data(current.copyWith(isSaving: true, message: null));

    final appointment = await _repository.createAppointment(draft);
    await load(
      patientId: current.patientId,
      status: current.statusFilter,
      date: current.dateFilter,
    );

    final latest = state.valueOrNull ?? current;
    state = AsyncValue.data(
      latest.copyWith(isSaving: false, message: 'Appointment saved.'),
    );

    return appointment;
  }

  Future<Appointment> updateAppointment(String appointmentId, AppointmentDraft draft) async {
    final current = state.valueOrNull ?? const AppointmentsState();
    state = AsyncValue.data(current.copyWith(isSaving: true, message: null));

    final appointment = await _repository.updateAppointment(appointmentId, draft);
    await load(
      patientId: current.patientId,
      status: current.statusFilter,
      date: current.dateFilter,
    );

    final latest = state.valueOrNull ?? current;
    state = AsyncValue.data(
      latest.copyWith(isSaving: false, message: 'Appointment saved.'),
    );

    return appointment;
  }

  Appointment? findById(String appointmentId) {
    final appointments = state.valueOrNull?.appointments ?? const <Appointment>[];
    for (final appointment in appointments) {
      if (appointment.id == appointmentId) {
        return appointment;
      }
    }

    return null;
  }
}
