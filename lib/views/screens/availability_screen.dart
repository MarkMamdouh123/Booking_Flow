import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/availability/availability_cubit.dart';
import '../../cubits/availability/availability_state.dart';
import '../../models/availability_model.dart';
import '../../utils/date_formatter.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  late List<DaySchedule> _weeklySchedule;
  late int _slotIntervalMinutes;

  static const List<String> weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Availability'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            tooltip: 'Save Schedule',
            onPressed: _saveAvailability,
          ),
        ],
      ),
      body: BlocConsumer<AvailabilityCubit, AvailabilityState>(
        listener: (context, state) {
          if (state is AvailabilityLoaded && state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.successMessage!), backgroundColor: Colors.green),
            );
          }
        },
        builder: (context, state) {
          if (state is AvailabilityLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AvailabilityLoaded) {
            _weeklySchedule = List.from(state.availability.weeklySchedule);
            _slotIntervalMinutes = state.availability.slotIntervalMinutes;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Slot Interval Configuration Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Appointment Slot Duration',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Length of each booking slot',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        DropdownButton<int>(
                          value: _slotIntervalMinutes,
                          items: const [
                            DropdownMenuItem(value: 15, child: Text('15 Mins')),
                            DropdownMenuItem(value: 30, child: Text('30 Mins')),
                            DropdownMenuItem(value: 45, child: Text('45 Mins')),
                            DropdownMenuItem(value: 60, child: Text('60 Mins')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _slotIntervalMinutes = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Weekly Schedule Header
                  Text(
                    'Weekly Business Hours',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 7,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final daySched = _weeklySchedule.firstWhere(
                        (s) => s.weekday == (index + 1),
                        orElse: () => DaySchedule(
                          weekday: index + 1,
                          isWorkingDay: index < 5,
                          startTime: '09:00 AM',
                          endTime: '05:00 PM',
                          breakStart: '01:00 PM',
                          breakEnd: '02:00 PM',
                        ),
                      );

                      return _buildDayScheduleCard(context, daySched, weekdays[index]);
                    },
                  ),

                  const SizedBox(height: 28),

                  // Blocked Dates / Holidays Manager
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Blackout Dates & Holidays',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Color(0xFF6366F1)),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null && context.mounted) {
                            context.read<AvailabilityCubit>().toggleBlockDate(date);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (state.availability.blockedDates.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: Text(
                          'No blackout dates set. Tap + to add holidays.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: state.availability.blockedDates.map((date) {
                        return Chip(
                          avatar: const Icon(Icons.block, size: 14, color: Colors.red),
                          label: Text(DateFormatter.formatDate(date)),
                          onDeleted: () {
                            context.read<AvailabilityCubit>().toggleBlockDate(date);
                          },
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _saveAvailability,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save Availability Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildDayScheduleCard(BuildContext context, DaySchedule day, String dayName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: day.isWorkingDay
              ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          // Day Name & Switch
          SizedBox(
            width: 120,
            child: Row(
              children: [
                Switch(
                  value: day.isWorkingDay,
                  onChanged: (val) {
                    _updateDaySchedule(day.copyWith(isWorkingDay: val));
                  },
                ),
                Expanded(
                  child: Text(
                    dayName.substring(0, 3),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: day.isWorkingDay ? null : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Working Hours
          if (day.isWorkingDay)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${day.startTime} - ${day.endTime}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          else
            const Expanded(
              child: Text(
                'Closed / Day Off',
                textAlign: TextAlign.end,
                style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  void _updateDaySchedule(DaySchedule updated) {
    setState(() {
      final idx = _weeklySchedule.indexWhere((s) => s.weekday == updated.weekday);
      if (idx >= 0) {
        _weeklySchedule[idx] = updated;
      }
    });
  }

  void _saveAvailability() {
    context.read<AvailabilityCubit>().updateSchedule(_weeklySchedule, _slotIntervalMinutes);
  }
}
