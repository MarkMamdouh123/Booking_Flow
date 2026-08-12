import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_booking_system/models/appointment_status.dart';
import 'package:flutter_booking_system/utils/date_formatter.dart';

void main() {
  group('Booking System Unit Tests', () {
    test('AppointmentStatus labels and colors are correct', () {
      expect(AppointmentStatus.pending.label, 'Pending');
      expect(AppointmentStatus.confirmed.label, 'Confirmed');
      expect(AppointmentStatus.completed.label, 'Completed');
      expect(AppointmentStatus.cancelled.label, 'Cancelled');
    });

    test('DateFormatter formats dates and currency accurately', () {
      final date = DateTime(2025, 5, 15);
      expect(DateFormatter.formatDate(date), 'May 15, 2025');
      expect(DateFormatter.formatCurrency(75.50), '\$75.50');
    });

    test('DateFormatter time slot generator excludes break hours', () {
      final slots = DateFormatter.generateTimeSlots(
        startTimeStr: '09:00 AM',
        endTimeStr: '05:00 PM',
        breakStartStr: '01:00 PM',
        breakEndStr: '02:00 PM',
        intervalMinutes: 60,
      );

      // Should generate 9 AM, 10 AM, 11 AM, 12 PM, 2 PM, 3 PM, 4 PM (7 slots)
      expect(slots.contains('09:00 AM'), isTrue);
      expect(slots.contains('01:00 PM'), isFalse); // Break time
      expect(slots.contains('02:00 PM'), isTrue);
    });
  });
}
