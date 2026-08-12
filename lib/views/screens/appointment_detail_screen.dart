import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/booking/booking_cubit.dart';
import '../../cubits/booking/booking_state.dart';
import '../../models/appointment_model.dart';
import '../../models/appointment_status.dart';
import '../../utils/date_formatter.dart';
import '../widgets/status_badge.dart';
import 'booking_form_screen.dart';

class AppointmentDetailScreen extends StatelessWidget {
  final String appointmentId;

  const AppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit / Reschedule',
            onPressed: () {
              final state = context.read<BookingCubit>().state;
              if (state is BookingLoaded) {
                final apt = state.allAppointments.firstWhere((a) => a.id == appointmentId);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingFormScreen(appointmentToEdit: apt),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete Appointment',
            onPressed: () => _confirmDeleteDialog(context),
          ),
        ],
      ),
      body: BlocConsumer<BookingCubit, BookingState>(
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
            final apt = state.allAppointments.firstWhere(
              (a) => a.id == appointmentId,
              orElse: () => AppointmentModel(
                id: 'not_found',
                clientName: 'Unknown',
                clientPhone: '',
                clientEmail: '',
                service: state.allAppointments.first.service,
                date: DateTime.now(),
                startTime: '09:00 AM',
                durationMinutes: 30,
                price: 0,
                status: AppointmentStatus.pending,
                notes: '',
                createdAt: DateTime.now(),
              ),
            );

            if (apt.id == 'not_found') {
              return const Center(child: Text('Appointment not found'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Status & Reference Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REF: #${apt.id.toUpperCase().substring(0, apt.id.length > 8 ? 8 : apt.id.length)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormatter.formatDate(apt.createdAt),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        StatusBadge(status: apt.status),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Client Details Card
                  _buildSectionTitle(context, 'Client Details'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(context, Icons.person_outline, 'Name', apt.clientName),
                        const Divider(height: 20),
                        _buildInfoRow(context, Icons.phone_outlined, 'Phone', apt.clientPhone),
                        if (apt.clientEmail.isNotEmpty) ...[
                          const Divider(height: 20),
                          _buildInfoRow(context, Icons.email_outlined, 'Email', apt.clientEmail),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Service & Booking Summary Card
                  _buildSectionTitle(context, 'Booking Summary'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(context, Icons.medical_services_outlined, 'Service', apt.service.name),
                        const Divider(height: 20),
                        _buildInfoRow(context, Icons.calendar_month_outlined, 'Date', DateFormatter.formatDate(apt.date)),
                        const Divider(height: 20),
                        _buildInfoRow(context, Icons.access_time_outlined, 'Time Slot', '${apt.startTime} - ${apt.endTime} (${apt.durationMinutes}m)'),
                        const Divider(height: 20),
                        _buildInfoRow(context, Icons.attach_money_outlined, 'Total Fee', DateFormatter.formatCurrency(apt.price), isHighlighted: true),
                      ],
                    ),
                  ),

                  if (apt.notes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSectionTitle(context, 'Notes'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Text(apt.notes, style: const TextStyle(fontSize: 13, height: 1.4)),
                    ),
                  ],

                  if (apt.cancellationReason != null && apt.cancellationReason!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSectionTitle(context, 'Cancellation Reason'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        apt.cancellationReason!,
                        style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Quick Action Workflow Buttons
                  _buildSectionTitle(context, 'Manage Status'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (apt.status != AppointmentStatus.completed && apt.status != AppointmentStatus.cancelled) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final nextStatus = apt.status == AppointmentStatus.pending
                                  ? AppointmentStatus.confirmed
                                  : AppointmentStatus.completed;
                              context.read<BookingCubit>().updateAppointmentStatus(apt.id, nextStatus);
                            },
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(
                              apt.status == AppointmentStatus.pending ? 'Confirm' : 'Mark Completed',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: apt.status == AppointmentStatus.pending
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],

                      if (apt.status != AppointmentStatus.cancelled) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showCancelReasonDialog(context, apt.id),
                            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                            label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ],
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, {bool isHighlighted = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isHighlighted ? Theme.of(context).colorScheme.primary : Colors.grey),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
            fontSize: isHighlighted ? 16 : 14,
            color: isHighlighted ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ],
    );
  }

  void _showCancelReasonDialog(BuildContext context, String id) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for cancelling this booking:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g. Client request, illness, scheduling conflict',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<BookingCubit>().cancelAppointment(id, reasonController.text);
              Navigator.pop(dialogCtx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: const Text('This action will permanently delete the appointment from Hive storage.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<BookingCubit>().deleteAppointment(appointmentId);
              Navigator.pop(dialogCtx); // close dialog
              Navigator.pop(context);   // return to list screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
