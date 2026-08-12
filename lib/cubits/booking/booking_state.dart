import 'package:equatable/equatable.dart';
import '../../models/appointment_model.dart';
import '../../models/appointment_status.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingLoaded extends BookingState {
  final List<AppointmentModel> allAppointments;
  final List<AppointmentModel> filteredAppointments;
  final AppointmentStatus? activeStatusFilter; // null = All
  final String searchQuery;
  final DateTime? selectedDateFilter;
  final String? message; // Toast/Snackbar success message

  const BookingLoaded({
    required this.allAppointments,
    required this.filteredAppointments,
    this.activeStatusFilter,
    this.searchQuery = '',
    this.selectedDateFilter,
    this.message,
  });

  BookingLoaded copyWith({
    List<AppointmentModel>? allAppointments,
    List<AppointmentModel>? filteredAppointments,
    AppointmentStatus? Function()? activeStatusFilter,
    String? searchQuery,
    DateTime? Function()? selectedDateFilter,
    String? Function()? message,
  }) {
    return BookingLoaded(
      allAppointments: allAppointments ?? this.allAppointments,
      filteredAppointments: filteredAppointments ?? this.filteredAppointments,
      activeStatusFilter: activeStatusFilter != null ? activeStatusFilter() : this.activeStatusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedDateFilter: selectedDateFilter != null ? selectedDateFilter() : this.selectedDateFilter,
      message: message != null ? message() : this.message,
    );
  }

  @override
  List<Object?> get props => [
        allAppointments,
        filteredAppointments,
        activeStatusFilter,
        searchQuery,
        selectedDateFilter,
        message,
      ];
}

class BookingSubmitting extends BookingState {}

class BookingValidationError extends BookingState {
  final String fieldName;
  final String validationMessage;

  const BookingValidationError({
    required this.fieldName,
    required this.validationMessage,
  });

  @override
  List<Object?> get props => [fieldName, validationMessage];
}

class BookingOperationSuccess extends BookingState {
  final String successMessage;

  const BookingOperationSuccess(this.successMessage);

  @override
  List<Object?> get props => [successMessage];
}

class BookingFailure extends BookingState {
  final String errorMessage;

  const BookingFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
