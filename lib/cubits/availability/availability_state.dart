import 'package:equatable/equatable.dart';
import '../../models/availability_model.dart';

abstract class AvailabilityState extends Equatable {
  const AvailabilityState();

  @override
  List<Object?> get props => [];
}

class AvailabilityInitial extends AvailabilityState {}

class AvailabilityLoading extends AvailabilityState {}

class AvailabilityLoaded extends AvailabilityState {
  final AvailabilityModel availability;
  final String? successMessage;

  const AvailabilityLoaded({required this.availability, this.successMessage});

  @override
  List<Object?> get props => [availability, successMessage];
}

class AvailabilityFailure extends AvailabilityState {
  final String errorMessage;

  const AvailabilityFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
