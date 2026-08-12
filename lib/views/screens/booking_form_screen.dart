import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/availability/availability_cubit.dart';
import '../../cubits/booking/booking_cubit.dart';
import '../../cubits/booking/booking_state.dart';
import '../../models/appointment_model.dart';
import '../../models/appointment_status.dart';
import '../../models/service_model.dart';
import '../../services/hive_service.dart';
import '../../utils/date_formatter.dart';
import '../widgets/time_slot_picker.dart';

class BookingFormScreen extends StatefulWidget {
  final AppointmentModel? appointmentToEdit;
  final DateTime? initialDate;

  const BookingFormScreen({
    super.key,
    this.appointmentToEdit,
    this.initialDate,
  });

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _notesController;

  late ServiceModel _selectedService;
  late DateTime _selectedDate;
  String? _selectedStartTime;

  String? _validationErrorMessage;

  @override
  void initState() {
    super.initState();
    final apt = widget.appointmentToEdit;

    _selectedService = apt?.service ?? HiveService.defaultServices.first;
    _selectedDate = apt?.date ?? widget.initialDate ?? DateTime.now();
    _selectedStartTime = apt?.startTime;

    _nameController = TextEditingController(text: apt?.clientName ?? '');
    _phoneController = TextEditingController(text: apt?.clientPhone ?? '');
    _emailController = TextEditingController(text: apt?.clientEmail ?? '');
    _notesController = TextEditingController(text: apt?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.appointmentToEdit != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get available slots from AvailabilityCubit
    final availableSlots = context.read<AvailabilityCubit>().getAvailableSlotsForDate(_selectedDate);

    // Get already booked slots for this date to mark as locked
    final allAppointments = HiveService.getAppointments();
    final bookedSlotsForDate = allAppointments
        .where((a) =>
            DateFormatter.isSameDay(a.date, _selectedDate) &&
            a.status != AppointmentStatus.cancelled &&
            (widget.appointmentToEdit == null || a.id != widget.appointmentToEdit!.id))
        .map((a) => a.startTime)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Appointment' : 'New Appointment'),
      ),
      body: BlocListener<BookingCubit, BookingState>(
        listener: (context, state) {
          if (state is BookingValidationError) {
            setState(() {
              _validationErrorMessage = state.validationMessage;
            });
          } else if (state is BookingOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.successMessage), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          } else if (state is BookingFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage), backgroundColor: Colors.red),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error Validation Banner
                if (_validationErrorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _validationErrorMessage!,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Step 1: Select Service
                Text(
                  '1. Select Service',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ServiceModel>(
                  value: _selectedService,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.medical_services_outlined),
                  ),
                  items: HiveService.defaultServices.map((service) {
                    return DropdownMenuItem(
                      value: service,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              service.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${DateFormatter.formatCurrency(service.price)} (${service.durationMinutes}m)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedService = val;
                        _validationErrorMessage = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Step 2: Select Date
                Text(
                  '2. Select Appointment Date',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                        _selectedStartTime = null; // reset selected slot
                        _validationErrorMessage = null;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              DateFormatter.formatDate(_selectedDate),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Step 3: Select Time Slot
                Text(
                  '3. Select Time Slot',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TimeSlotPicker(
                  availableSlots: availableSlots,
                  bookedSlots: bookedSlotsForDate,
                  selectedSlot: _selectedStartTime,
                  onSlotSelected: (slot) {
                    setState(() {
                      _selectedStartTime = slot;
                      _validationErrorMessage = null;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Step 4: Client Information
                Text(
                  '4. Client Details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Client Full Name *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter client name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter phone number' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address (Optional)',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Special Notes / Instructions',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Button
                BlocBuilder<BookingCubit, BookingState>(
                  builder: (context, state) {
                    final isSubmitting = state is BookingSubmitting;

                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                isEditing ? 'Save Changes' : 'Confirm & Book Appointment',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_selectedStartTime == null) {
      setState(() {
        _validationErrorMessage = 'Please select a valid available time slot.';
      });
      return;
    }

    if (_formKey.currentState!.validate()) {
      final cubit = context.read<BookingCubit>();

      if (widget.appointmentToEdit != null) {
        final updated = widget.appointmentToEdit!.copyWith(
          clientName: _nameController.text.trim(),
          clientPhone: _phoneController.text.trim(),
          clientEmail: _emailController.text.trim(),
          service: _selectedService,
          date: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
          startTime: _selectedStartTime!,
          durationMinutes: _selectedService.durationMinutes,
          price: _selectedService.price,
          notes: _notesController.text.trim(),
        );
        cubit.updateAppointment(updated);
      } else {
        cubit.createAppointment(
          clientName: _nameController.text,
          clientPhone: _phoneController.text,
          clientEmail: _emailController.text,
          service: _selectedService,
          date: _selectedDate,
          startTime: _selectedStartTime!,
          notes: _notesController.text,
        );
      }
    }
  }
}
