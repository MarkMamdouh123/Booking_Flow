import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

class DaySchedule extends Equatable {
  final int weekday; // 1 = Monday, 7 = Sunday
  final bool isWorkingDay;
  final String startTime; // "09:00 AM"
  final String endTime;   // "05:00 PM"
  final String breakStart; // "01:00 PM"
  final String breakEnd;   // "02:00 PM"

  const DaySchedule({
    required this.weekday,
    required this.isWorkingDay,
    required this.startTime,
    required this.endTime,
    required this.breakStart,
    required this.breakEnd,
  });

  DaySchedule copyWith({
    int? weekday,
    bool? isWorkingDay,
    String? startTime,
    String? endTime,
    String? breakStart,
    String? breakEnd,
  }) {
    return DaySchedule(
      weekday: weekday ?? this.weekday,
      isWorkingDay: isWorkingDay ?? this.isWorkingDay,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breakStart: breakStart ?? this.breakStart,
      breakEnd: breakEnd ?? this.breakEnd,
    );
  }

  @override
  List<Object?> get props => [weekday, isWorkingDay, startTime, endTime, breakStart, breakEnd];
}

class DayScheduleAdapter extends TypeAdapter<DaySchedule> {
  @override
  final int typeId = 3;

  @override
  DaySchedule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DaySchedule(
      weekday: fields[0] as int,
      isWorkingDay: fields[1] as bool,
      startTime: fields[2] as String,
      endTime: fields[3] as String,
      breakStart: fields[4] as String,
      breakEnd: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DaySchedule obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)..write(obj.weekday)
      ..writeByte(1)..write(obj.isWorkingDay)
      ..writeByte(2)..write(obj.startTime)
      ..writeByte(3)..write(obj.endTime)
      ..writeByte(4)..write(obj.breakStart)
      ..writeByte(5)..write(obj.breakEnd);
  }
}

class AvailabilityModel extends HiveObject {
  final List<DaySchedule> weeklySchedule;
  final List<DateTime> blockedDates; // Holidays / Blackout dates
  final int slotIntervalMinutes;     // 30, 45, 60

  AvailabilityModel({
    required this.weeklySchedule,
    required this.blockedDates,
    this.slotIntervalMinutes = 30,
  });

  factory AvailabilityModel.defaultSchedule() {
    return AvailabilityModel(
      slotIntervalMinutes: 30,
      blockedDates: const [],
      weeklySchedule: List.generate(7, (index) {
        final weekday = index + 1;
        final isWeekend = weekday == 6 || weekday == 7; // Sat & Sun
        return DaySchedule(
          weekday: weekday,
          isWorkingDay: !isWeekend,
          startTime: '09:00 AM',
          endTime: '05:00 PM',
          breakStart: '01:00 PM',
          breakEnd: '02:00 PM',
        );
      }),
    );
  }

  AvailabilityModel copyWith({
    List<DaySchedule>? weeklySchedule,
    List<DateTime>? blockedDates,
    int? slotIntervalMinutes,
  }) {
    return AvailabilityModel(
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
      blockedDates: blockedDates ?? this.blockedDates,
      slotIntervalMinutes: slotIntervalMinutes ?? this.slotIntervalMinutes,
    );
  }

  List<Object?> get props => [weeklySchedule, blockedDates, slotIntervalMinutes];
}

class AvailabilityModelAdapter extends TypeAdapter<AvailabilityModel> {
  @override
  final int typeId = 4;

  @override
  AvailabilityModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AvailabilityModel(
      weeklySchedule: (fields[0] as List).cast<DaySchedule>(),
      blockedDates: (fields[1] as List).cast<DateTime>(),
      slotIntervalMinutes: fields[2] as int? ?? 30,
    );
  }

  @override
  void write(BinaryWriter writer, AvailabilityModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)..write(obj.weeklySchedule)
      ..writeByte(1)..write(obj.blockedDates)
      ..writeByte(2)..write(obj.slotIntervalMinutes);
  }
}
