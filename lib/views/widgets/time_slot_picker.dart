import 'package:flutter/material.dart';

class TimeSlotPicker extends StatelessWidget {
  final List<String> availableSlots;
  final List<String> bookedSlots;
  final String? selectedSlot;
  final ValueChanged<String> onSlotSelected;

  const TimeSlotPicker({
    super.key,
    required this.availableSlots,
    required this.bookedSlots,
    required this.selectedSlot,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (availableSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No available time slots for this date.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: availableSlots.map((slot) {
        final isBooked = bookedSlots.contains(slot);
        final isSelected = selectedSlot == slot;

        Color bgColor;
        Color textColor;
        BorderSide borderSide;

        if (isBooked) {
          bgColor = isDark ? const Color(0xFF334155).withOpacity(0.4) : const Color(0xFFE2E8F0);
          textColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
          borderSide = BorderSide.none;
        } else if (isSelected) {
          bgColor = Theme.of(context).colorScheme.primary;
          textColor = Colors.white;
          borderSide = BorderSide(color: Theme.of(context).colorScheme.primary, width: 2);
        } else {
          bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
          textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
          borderSide = BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          );
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isBooked ? null : () => onSlotSelected(slot),
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.fromBorderSide(borderSide),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isBooked ? Icons.lock_clock : Icons.access_time,
                    size: 14,
                    color: textColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    slot,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: textColor,
                      decoration: isBooked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
