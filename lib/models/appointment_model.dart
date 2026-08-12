import 'package:hive/hive.dart';
import 'appointment_status.dart';
import 'service_model.dart';

class AppointmentModel extends HiveObject {
  final String id;
  final String clientName;
  final String clientPhone;
  final String clientEmail;
  final ServiceModel service;
  final DateTime date;
  final String startTime; // "09:00 AM" format
  final int durationMinutes;
  final double price;
  final AppointmentStatus status;
  final String notes;
  final String? cancellationReason;
  final DateTime createdAt;

  AppointmentModel({
    required this.id,
    required this.clientName,
    required this.clientPhone,
    required this.clientEmail,
    required this.service,
    required this.date,
    required this.startTime,
    required this.durationMinutes,
    required this.price,
    required this.status,
    required this.notes,
    this.cancellationReason,
    required this.createdAt,
  });

  // Calculate start DateTime
  DateTime get startDateTime {
    final parts = _parseTimeOfDay(startTime);
    return DateTime(date.year, date.month, date.day, parts.hour, parts.minute);
  }

  // Calculate end DateTime
  DateTime get endDateTime {
    return startDateTime.add(Duration(minutes: durationMinutes));
  }

  String get endTime {
    final end = endDateTime;
    final hour = end.hour == 0 ? 12 : (end.hour > 12 ? end.hour - 12 : end.hour);
    final minute = end.minute.toString().padLeft(2, '0');
    final period = end.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  static ({int hour, int minute}) _parseTimeOfDay(String timeStr) {
    try {
      final clean = timeStr.trim().toUpperCase();
      final isPm = clean.contains('PM');
      final isAm = clean.contains('AM');
      final timeParts = clean.replaceAll(RegExp(r'[^\d:]'), '').split(':');
      
      int hour = int.parse(timeParts[0]);
      int minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
      
      if (isPm && hour < 12) hour += 12;
      if (isAm && hour == 12) hour = 0;
      
      return (hour: hour, minute: minute);
    } catch (_) {
      return (hour: 9, minute: 0);
    }
  }

  AppointmentModel copyWith({
    String? id,
    String? clientName,
    String? clientPhone,
    String? clientEmail,
    ServiceModel? service,
    DateTime? date,
    String? startTime,
    int? durationMinutes,
    double? price,
    AppointmentStatus? status,
    String? notes,
    String? cancellationReason,
    DateTime? createdAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      service: service ?? this.service,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      price: price ?? this.price,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  List<Object?> get props => [
        id,
        clientName,
        clientPhone,
        clientEmail,
        service,
        date,
        startTime,
        durationMinutes,
        price,
        status,
        notes,
        cancellationReason,
        createdAt,
      ];
}

class AppointmentModelAdapter extends TypeAdapter<AppointmentModel> {
  @override
  final int typeId = 2;

  @override
  AppointmentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppointmentModel(
      id: fields[0] as String,
      clientName: fields[1] as String,
      clientPhone: fields[2] as String,
      clientEmail: fields[3] as String,
      service: fields[4] as ServiceModel,
      date: fields[5] as DateTime,
      startTime: fields[6] as String,
      durationMinutes: fields[7] as int,
      price: (fields[8] as num).toDouble(),
      status: fields[9] as AppointmentStatus,
      notes: fields[10] as String,
      cancellationReason: fields[11] as String?,
      createdAt: fields[12] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AppointmentModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.clientName)
      ..writeByte(2)..write(obj.clientPhone)
      ..writeByte(3)..write(obj.clientEmail)
      ..writeByte(4)..write(obj.service)
      ..writeByte(5)..write(obj.date)
      ..writeByte(6)..write(obj.startTime)
      ..writeByte(7)..write(obj.durationMinutes)
      ..writeByte(8)..write(obj.price)
      ..writeByte(9)..write(obj.status)
      ..writeByte(10)..write(obj.notes)
      ..writeByte(11)..write(obj.cancellationReason)
      ..writeByte(12)..write(obj.createdAt);
  }
}
