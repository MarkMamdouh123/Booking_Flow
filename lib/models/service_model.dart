import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

class ServiceModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final int durationMinutes;
  final double price;
  final String category;
  final String iconName;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.price,
    required this.category,
    required this.iconName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'durationMinutes': durationMinutes,
      'price': price,
      'category': category,
      'iconName': iconName,
    };
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      durationMinutes: map['durationMinutes']?.toInt() ?? 30,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? 'General',
      iconName: map['iconName'] ?? 'event',
    );
  }

  @override
  List<Object?> get props => [id, name, description, durationMinutes, price, category, iconName];
}

class ServiceModelAdapter extends TypeAdapter<ServiceModel> {
  @override
  final int typeId = 1;

  @override
  ServiceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ServiceModel(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      durationMinutes: fields[3] as int,
      price: (fields[4] as num).toDouble(),
      category: fields[5] as String,
      iconName: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ServiceModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.name)
      ..writeByte(2)..write(obj.description)
      ..writeByte(3)..write(obj.durationMinutes)
      ..writeByte(4)..write(obj.price)
      ..writeByte(5)..write(obj.category)
      ..writeByte(6)..write(obj.iconName);
  }
}
