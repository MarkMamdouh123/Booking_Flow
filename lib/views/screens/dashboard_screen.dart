import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/booking/booking_cubit.dart';
import '../../cubits/booking/booking_state.dart';
import '../../models/appointment_status.dart';
import '../../utils/date_formatter.dart';
import '../widgets/appointment_card.dart';
import '../widgets/metric_card.dart';
import 'appointment_detail_screen.dart';
import 'booking_form_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<BookingCubit, BookingState>(
          listener: (context, state) {
            if (state is BookingOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.successMessage), backgroundColor: Colors.green),
              );
            }
          },
          builder: (context, state) {
            if (state is BookingLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is BookingLoaded) {
              final all = state.allAppointments;

              // Compute Metrics
              final totalBookings = all.length;
              final completedCount = all.where((a) => a.status == AppointmentStatus.completed).length;
              final completionRate = totalBookings > 0 ? ((completedCount / totalBookings) * 100).toStringAsFixed(0) : '0';
              
              final totalRevenue = all
                  .where((a) => a.status != AppointmentStatus.cancelled)
                  .fold(0.0, (sum, a) => sum + a.price);

              final todayAppointments = all.where((a) => DateFormatter.isToday(a.date)).toList();
              final upcomingAppointments = all
                  .where((a) => a.date.isAfter(DateTime.now().subtract(const Duration(days: 1))) && a.status != AppointmentStatus.cancelled)
                  .take(4)
                  .toList();

              return RefreshIndicator(
                onRefresh: () async => context.read<BookingCubit>().loadAppointments(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Welcome Banner
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Appointment Dashboard',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormatter.formatDate(DateTime.now()),
                                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const BookingFormScreen()),
                              );
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('New Booking'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Metrics Grid
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.35,
                        children: [
                          MetricCard(
                            title: 'Total Bookings',
                            value: totalBookings.toString(),
                            subtitle: '${todayAppointments.length} today',
                            icon: Icons.calendar_today_rounded,
                            iconColor: const Color(0xFF6366F1),
                          ),
                          MetricCard(
                            title: 'Est. Revenue',
                            value: DateFormatter.formatCurrency(totalRevenue),
                            subtitle: 'Active appointments',
                            icon: Icons.attach_money_rounded,
                            iconColor: const Color(0xFF10B981),
                          ),
                          MetricCard(
                            title: 'Completion Rate',
                            value: '$completionRate%',
                            subtitle: '$completedCount finished',
                            icon: Icons.check_circle_outline_rounded,
                            iconColor: const Color(0xFF3B82F6),
                          ),
                          MetricCard(
                            title: 'Pending Action',
                            value: all.where((a) => a.status == AppointmentStatus.pending).length.toString(),
                            subtitle: 'Requires confirmation',
                            icon: Icons.error_outline_rounded,
                            iconColor: const Color(0xFFF59E0B),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Today's Schedule Timeline Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Today's Schedule (${todayAppointments.length})",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (todayAppointments.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withOpacity(0.2)),
                          ),
                          child: const Center(
                            child: Text('No appointments scheduled for today.', style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: todayAppointments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final apt = todayAppointments[index];
                            return AppointmentCard(
                              appointment: apt,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AppointmentDetailScreen(appointmentId: apt.id),
                                  ),
                                );
                              },
                            );
                          },
                        ),

                      const SizedBox(height: 28),

                      // Upcoming Bookings Section
                      Text(
                        'Upcoming Appointments',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: upcomingAppointments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final apt = upcomingAppointments[index];
                          return AppointmentCard(
                            appointment: apt,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AppointmentDetailScreen(appointmentId: apt.id),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}
