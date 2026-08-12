import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _dayOfWeekFormat = DateFormat('EEEE');
  static final DateFormat _shortDayFormat = DateFormat('EEE');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatDayOfWeek(DateTime date) => _dayOfWeekFormat.format(date);
  static String formatShortDay(DateTime date) => _shortDayFormat.format(date);
  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);
  static String formatCurrency(double amount) => _currencyFormat.format(amount);

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  // Time slot generator
  static List<String> generateTimeSlots({
    required String startTimeStr,
    required String endTimeStr,
    required String breakStartStr,
    required String breakEndStr,
    required int intervalMinutes,
  }) {
    final slots = <String>[];

    final start = _parseTimeString(startTimeStr);
    final end = _parseTimeString(endTimeStr);
    final breakStart = _parseTimeString(breakStartStr);
    final breakEnd = _parseTimeString(breakEndStr);

    int currentMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final bStartMinutes = breakStart.hour * 60 + breakStart.minute;
    final bEndMinutes = breakEnd.hour * 60 + breakEnd.minute;

    while (currentMinutes + intervalMinutes <= endMinutes) {
      // Check if slot falls in break time
      final slotEndMinutes = currentMinutes + intervalMinutes;
      final isDuringBreak = (currentMinutes >= bStartMinutes && currentMinutes < bEndMinutes) ||
          (slotEndMinutes > bStartMinutes && slotEndMinutes <= bEndMinutes);

      if (!isDuringBreak) {
        final hour = currentMinutes ~/ 60;
        final minute = currentMinutes % 60;
        slots.add(_formatTimeFromMinutes(hour, minute));
      }

      currentMinutes += intervalMinutes;
    }

    return slots;
  }

  static ({int hour, int minute}) _parseTimeString(String timeStr) {
    try {
      final clean = timeStr.trim().toUpperCase();
      final isPm = clean.contains('PM');
      final isAm = clean.contains('AM');
      final timeParts = clean.replaceAll(RegExp(r'[^\d:]'), '').split(':');

      int hour = int.parse(timeParts[0]);
      int minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;

      if (isPm && hour < 12) hour += 12;
      if (isAm && hour == 12) hour = 0;

      return (hour: hour, minute: minute);
    } catch (_) {
      return (hour: 9, minute: 0);
    }
  }

  static String _formatTimeFromMinutes(int hour, int minute) {
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    return '${displayHour.toString().padLeft(2, '0')}:$minuteStr $period';
  }
}
