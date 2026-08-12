import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

enum AppointmentStatus {
  pending,
  confirmed,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Pending';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case AppointmentStatus.pending:
        return const Color(0xFFF59E0B); // Amber
      case AppointmentStatus.confirmed:
        return const Color(0xFF3B82F6); // Blue
      case AppointmentStatus.completed:
        return const Color(0xFF10B981); // Emerald Green
      case AppointmentStatus.cancelled:
        return const Color(0xFFEF4444); // Red
    }
  }
}

class AppointmentStatusAdapter extends TypeAdapter<AppointmentStatus> {
  @override
  final int typeId = 0;

  @override
  AppointmentStatus read(BinaryReader reader) {
    final index = reader.readInt();
    return AppointmentStatus.values.elementAt(
      index >= 0 && index < AppointmentStatus.values.length ? index : 0,
    );
  }

  @override
  void write(BinaryWriter writer, AppointmentStatus obj) {
    writer.writeInt(obj.index);
  }
}
