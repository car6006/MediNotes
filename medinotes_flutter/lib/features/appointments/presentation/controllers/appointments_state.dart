import '../../domain/entities/appointment.dart';

class AppointmentsState {
  const AppointmentsState({
    this.appointments = const [],
    this.patientId,
    this.statusFilter,
    this.dateFilter,
    this.isSaving = false,
    this.message,
  });

  final List<Appointment> appointments;
  final String? patientId;
  final String? statusFilter;
  final DateTime? dateFilter;
  final bool isSaving;
  final String? message;

  AppointmentsState copyWith({
    List<Appointment>? appointments,
    Object? patientId = _sentinel,
    Object? statusFilter = _sentinel,
    Object? dateFilter = _sentinel,
    bool? isSaving,
    Object? message = _sentinel,
  }) {
    return AppointmentsState(
      appointments: appointments ?? this.appointments,
      patientId: identical(patientId, _sentinel) ? this.patientId : patientId as String?,
      statusFilter: identical(statusFilter, _sentinel)
          ? this.statusFilter
          : statusFilter as String?,
      dateFilter: identical(dateFilter, _sentinel)
          ? this.dateFilter
          : dateFilter as DateTime?,
      isSaving: isSaving ?? this.isSaving,
      message: identical(message, _sentinel) ? this.message : message as String?,
    );
  }

  static const Object _sentinel = Object();
}
