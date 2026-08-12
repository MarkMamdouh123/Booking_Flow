import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/appointment_model.dart';
import '../../models/appointment_status.dart';
import '../../models/service_model.dart';
import '../../services/hive_service.dart';
import '../../utils/date_formatter.dart';
import 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  BookingCubit() : super(BookingInitial()) {
    loadAppointments();
  }

  void loadAppointments() {
    try {
      emit(BookingLoading());
      final all = HiveService.getAppointments();
      emit(BookingLoaded(
        allAppointments: all,
        filteredAppointments: all,
      ));
    } catch (e) {
      emit(BookingFailure('Failed to load appointments: ${e.toString()}'));
    }
  }

  // Filter & Search Logic
  void searchAppointments(String query) {
    if (state is! BookingLoaded) return;
    final current = state as BookingLoaded;
    _applyFiltersAndEmit(
      current,
      searchQuery: query,
    );
  }

  void filterByStatus(AppointmentStatus? status) {
    if (state is! BookingLoaded) return;
    final current = state as BookingLoaded;
    _applyFiltersAndEmit(
      current,
      activeStatusFilter: () => status,
    );
  }

  void filterByDate(DateTime? date) {
    if (state is! BookingLoaded) return;
    final current = state as BookingLoaded;
    _applyFiltersAndEmit(
      current,
      selectedDateFilter: () => date,
    );
  }

  void clearFilters() {
    if (state is! BookingLoaded) return;
    final current = state as BookingLoaded;
    _applyFiltersAndEmit(
      current,
      searchQuery: '',
      activeStatusFilter: () => null,
      selectedDateFilter: () => null,
    );
  }

  // Double-booking validation helper
  bool isSlotDoubleBooked({
    required DateTime date,
    required String startTime,
    required int durationMinutes,
    String? excludeAppointmentId,
  }) {
    final all = HiveService.getAppointments();
    
    // Parse target proposed start and end times
    final targetTempApt = AppointmentModel(
      id: 'temp',
      clientName: '',
      clientPhone: '',
      clientEmail: '',
      service: HiveService.defaultServices[0],
      date: date,
      startTime: startTime,
      durationMinutes: durationMinutes,
      price: 0,
      status: AppointmentStatus.pending,
      notes: '',
      createdAt: DateTime.now(),
    );

    final proposedStart = targetTempApt.startDateTime;
    final proposedEnd = targetTempApt.endDateTime;

    for (final apt in all) {
      // Ignore cancelled bookings and self when editing
      if (apt.status == AppointmentStatus.cancelled) continue;
      if (excludeAppointmentId != null && apt.id == excludeAppointmentId) continue;

      if (DateFormatter.isSameDay(apt.date, date)) {
        final existingStart = apt.startDateTime;
        final existingEnd = apt.endDateTime;

        // Check for time overlap: [Start1, End1) overlaps with [Start2, End2)
        if (proposedStart.isBefore(existingEnd) && proposedEnd.isAfter(existingStart)) {
          return true; // Overlap detected!
        }
      }
    }
    return false;
  }

  // Create Appointment
  Future<void> createAppointment({
    required String clientName,
    required String clientPhone,
    required String clientEmail,
    required ServiceModel service,
    required DateTime date,
    required String startTime,
    required String notes,
  }) async {
    // 1. Validation Checks
    if (clientName.trim().isEmpty) {
      emit(const BookingValidationError(fieldName: 'clientName', validationMessage: 'Client name is required.'));
      _restorePreviousState();
      return;
    }
    if (clientPhone.trim().isEmpty) {
      emit(const BookingValidationError(fieldName: 'clientPhone', validationMessage: 'Phone number is required.'));
      _restorePreviousState();
      return;
    }

    // Check double-booking
    if (isSlotDoubleBooked(date: date, startTime: startTime, durationMinutes: service.durationMinutes)) {
      emit(BookingValidationError(
        fieldName: 'startTime',
        validationMessage: 'Time slot $startTime is already booked! Please select another slot.',
      ));
      _restorePreviousState();
      return;
    }

    try {
      emit(BookingSubmitting());

      final newAppointment = AppointmentModel(
        id: 'apt_${DateTime.now().millisecondsSinceEpoch}',
        clientName: clientName.trim(),
        clientPhone: clientPhone.trim(),
        clientEmail: clientEmail.trim(),
        service: service,
        date: DateTime(date.year, date.month, date.day),
        startTime: startTime,
        durationMinutes: service.durationMinutes,
        price: service.price,
        status: AppointmentStatus.confirmed,
        notes: notes.trim(),
        createdAt: DateTime.now(),
      );

      await HiveService.saveAppointment(newAppointment);

      emit(const BookingOperationSuccess('Appointment booked successfully!'));
      loadAppointments();
    } catch (e) {
      emit(BookingFailure('Failed to create appointment: ${e.toString()}'));
    }
  }

  // Update Appointment
  Future<void> updateAppointment(AppointmentModel appointment) async {
    if (appointment.clientName.trim().isEmpty) {
      emit(const BookingValidationError(fieldName: 'clientName', validationMessage: 'Client name cannot be empty.'));
      _restorePreviousState();
      return;
    }

    // Check double-booking excluding current appointment
    if (isSlotDoubleBooked(
      date: appointment.date,
      startTime: appointment.startTime,
      durationMinutes: appointment.durationMinutes,
      excludeAppointmentId: appointment.id,
    )) {
      emit(BookingValidationError(
        fieldName: 'startTime',
        validationMessage: 'Selected time slot overlaps with another appointment.',
      ));
      _restorePreviousState();
      return;
    }

    try {
      emit(BookingSubmitting());
      await HiveService.saveAppointment(appointment);
      emit(const BookingOperationSuccess('Appointment updated successfully!'));
      loadAppointments();
    } catch (e) {
      emit(BookingFailure('Failed to update appointment: ${e.toString()}'));
    }
  }

  // Update Status (Pending, Confirmed, Completed)
  Future<void> updateAppointmentStatus(String id, AppointmentStatus newStatus) async {
    try {
      final all = HiveService.getAppointments();
      final apt = all.firstWhere((a) => a.id == id);
      final updated = apt.copyWith(status: newStatus);
      await HiveService.saveAppointment(updated);
      emit(BookingOperationSuccess('Status updated to ${newStatus.label}'));
      loadAppointments();
    } catch (e) {
      emit(BookingFailure('Failed to update status: ${e.toString()}'));
    }
  }

  // Cancel Appointment with Reason
  Future<void> cancelAppointment(String id, String reason) async {
    try {
      final all = HiveService.getAppointments();
      final apt = all.firstWhere((a) => a.id == id);
      final updated = apt.copyWith(
        status: AppointmentStatus.cancelled,
        cancellationReason: reason.trim().isEmpty ? 'Cancelled by provider' : reason.trim(),
      );
      await HiveService.saveAppointment(updated);
      emit(const BookingOperationSuccess('Appointment cancelled successfully'));
      loadAppointments();
    } catch (e) {
      emit(BookingFailure('Failed to cancel appointment: ${e.toString()}'));
    }
  }

  // Delete Appointment
  Future<void> deleteAppointment(String id) async {
    try {
      await HiveService.deleteAppointment(id);
      emit(const BookingOperationSuccess('Appointment deleted'));
      loadAppointments();
    } catch (e) {
      emit(BookingFailure('Failed to delete appointment: ${e.toString()}'));
    }
  }

  // Private Helper to restore Loaded state after validation error warning
  void _restorePreviousState() {
    final all = HiveService.getAppointments();
    emit(BookingLoaded(
      allAppointments: all,
      filteredAppointments: all,
    ));
  }

  void _applyFiltersAndEmit(
    BookingLoaded current, {
    String? searchQuery,
    AppointmentStatus? Function()? activeStatusFilter,
    DateTime? Function()? selectedDateFilter,
  }) {
    final query = searchQuery ?? current.searchQuery;
    final status = activeStatusFilter != null ? activeStatusFilter() : current.activeStatusFilter;
    final date = selectedDateFilter != null ? selectedDateFilter() : current.selectedDateFilter;

    List<AppointmentModel> filtered = List.from(current.allAppointments);

    // Search query filter
    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      filtered = filtered.where((a) {
        return a.clientName.toLowerCase().contains(q) ||
            a.clientPhone.toLowerCase().contains(q) ||
            a.clientEmail.toLowerCase().contains(q) ||
            a.service.name.toLowerCase().contains(q);
      }).toList();
    }

    // Status filter
    if (status != null) {
      filtered = filtered.where((a) => a.status == status).toList();
    }

    // Date filter
    if (date != null) {
      filtered = filtered.where((a) => DateFormatter.isSameDay(a.date, date)).toList();
    }

    emit(current.copyWith(
      filteredAppointments: filtered,
      searchQuery: query,
      activeStatusFilter: () => status,
      selectedDateFilter: () => date,
    ));
  }
}
