import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/availability_model.dart';
import '../../services/hive_service.dart';
import '../../utils/date_formatter.dart';
import 'availability_state.dart';

class AvailabilityCubit extends Cubit<AvailabilityState> {
  AvailabilityCubit() : super(AvailabilityInitial()) {
    loadAvailability();
  }

  void loadAvailability() {
    try {
      emit(AvailabilityLoading());
      final availability = HiveService.getAvailability();
      emit(AvailabilityLoaded(availability: availability));
    } catch (e) {
      emit(AvailabilityFailure('Failed to load schedule: ${e.toString()}'));
    }
  }

  Future<void> updateSchedule(List<DaySchedule> updatedSchedule, int intervalMinutes) async {
    try {
      if (state is AvailabilityLoaded) {
        final current = (state as AvailabilityLoaded).availability;
        final updated = current.copyWith(
          weeklySchedule: updatedSchedule,
          slotIntervalMinutes: intervalMinutes,
        );
        await HiveService.saveAvailability(updated);
        emit(AvailabilityLoaded(
          availability: updated,
          successMessage: 'Availability schedule saved successfully!',
        ));
      }
    } catch (e) {
      emit(AvailabilityFailure('Failed to update schedule: ${e.toString()}'));
    }
  }

  Future<void> toggleBlockDate(DateTime date) async {
    try {
      if (state is AvailabilityLoaded) {
        final current = (state as AvailabilityLoaded).availability;
        final normalized = DateTime(date.year, date.month, date.day);
        final blocked = List<DateTime>.from(current.blockedDates);

        final index = blocked.indexWhere((d) => DateFormatter.isSameDay(d, normalized));
        if (index >= 0) {
          blocked.removeAt(index);
        } else {
          blocked.add(normalized);
        }

        final updated = current.copyWith(blockedDates: blocked);
        await HiveService.saveAvailability(updated);
        emit(AvailabilityLoaded(
          availability: updated,
          successMessage: index >= 0 ? 'Date unblocked' : 'Date blocked successfully',
        ));
      }
    } catch (e) {
      emit(AvailabilityFailure('Failed to block/unblock date: ${e.toString()}'));
    }
  }

  // Get available slots for a given date considering provider schedule & blocked dates
  List<String> getAvailableSlotsForDate(DateTime date) {
    if (state is! AvailabilityLoaded) return [];
    final avail = (state as AvailabilityLoaded).availability;

    // Check if date is blocked
    final normalized = DateTime(date.year, date.month, date.day);
    if (avail.blockedDates.any((d) => DateFormatter.isSameDay(d, normalized))) {
      return []; // Day blocked
    }

    // Find weekday schedule (1=Mon ... 7=Sun)
    final daySchedule = avail.weeklySchedule.firstWhere(
      (s) => s.weekday == date.weekday,
      orElse: () => DaySchedule(
        weekday: date.weekday,
        isWorkingDay: false,
        startTime: '09:00 AM',
        endTime: '05:00 PM',
        breakStart: '01:00 PM',
        breakEnd: '02:00 PM',
      ),
    );

    if (!daySchedule.isWorkingDay) return [];

    return DateFormatter.generateTimeSlots(
      startTimeStr: daySchedule.startTime,
      endTimeStr: daySchedule.endTime,
      breakStartStr: daySchedule.breakStart,
      breakEndStr: daySchedule.breakEnd,
      intervalMinutes: avail.slotIntervalMinutes,
    );
  }
}
