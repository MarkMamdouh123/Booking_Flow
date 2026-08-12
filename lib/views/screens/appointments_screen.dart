import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/booking/booking_cubit.dart';
import '../../cubits/booking/booking_state.dart';
import '../../models/appointment_status.dart';
import '../../utils/date_formatter.dart';
import '../widgets/appointment_card.dart';
import '../widgets/empty_state_view.dart';
import 'appointment_detail_screen.dart';
import 'booking_form_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_off_rounded),
            tooltip: 'Clear Filters',
            onPressed: () {
              _searchController.clear();
              context.read<BookingCubit>().clearFilters();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header Container
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: Theme.of(context).appBarTheme.backgroundColor,
            child: Column(
              children: [
                // Search Input Field
                TextField(
                  controller: _searchController,
                  onChanged: (val) => context.read<BookingCubit>().searchAppointments(val),
                  decoration: InputDecoration(
                    hintText: 'Search client name, service or phone...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              context.read<BookingCubit>().searchAppointments('');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),

                // Status Filter Pills
                BlocBuilder<BookingCubit, BookingState>(
                  builder: (context, state) {
                    AppointmentStatus? activeStatus;
                    DateTime? selectedDate;

                    if (state is BookingLoaded) {
                      activeStatus = state.activeStatusFilter;
                      selectedDate = state.selectedDateFilter;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(
                                context,
                                label: 'All',
                                isSelected: activeStatus == null,
                                onTap: () => context.read<BookingCubit>().filterByStatus(null),
                              ),
                              const SizedBox(width: 8),
                              ...AppointmentStatus.values.map((status) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _buildFilterChip(
                                    context,
                                    label: status.label,
                                    isSelected: activeStatus == status,
                                    color: status.color,
                                    onTap: () => context.read<BookingCubit>().filterByStatus(status),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        if (selectedDate != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Chip(
                                avatar: const Icon(Icons.calendar_month, size: 14),
                                label: Text('Date: ${DateFormatter.formatDate(selectedDate)}'),
                                onDeleted: () => context.read<BookingCubit>().filterByDate(null),
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // List Body
          Expanded(
            child: BlocBuilder<BookingCubit, BookingState>(
              builder: (context, state) {
                if (state is BookingLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is BookingLoaded) {
                  final list = state.filteredAppointments;

                  if (list.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.calendar_today_outlined,
                      title: 'No Appointments Found',
                      message: state.searchQuery.isNotEmpty || state.activeStatusFilter != null
                          ? 'Try adjusting your search or filter parameters.'
                          : 'You have no appointments booked yet.',
                      actionLabel: 'Add First Booking',
                      onAction: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BookingFormScreen()),
                        );
                      },
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => context.read<BookingCubit>().loadAppointments(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final apt = list[index];
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
                  );
                }

                return const SizedBox();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BookingFormScreen()),
          );
        },
        tooltip: 'New Appointment',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    final activeColor = color ?? Theme.of(context).colorScheme.primary;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: activeColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? activeColor : Theme.of(context).textTheme.bodyMedium?.color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? activeColor : Colors.grey.withOpacity(0.3),
      ),
    );
  }
}
