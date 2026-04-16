// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_stroke.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveStrokeAdapter extends TypeAdapter<HiveStroke> {
  @override
  final int typeId = 11;

  @override
  HiveStroke read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveStroke(
      id: fields[0] as String?,
      points: (fields[1] as List).cast<Offset>(),
      colorValue: fields[2] as int,
      size: fields[3] as double,
      type: fields[4] as StrokeType,
    );
  }

  @override
  void write(BinaryWriter writer, HiveStroke obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.points)
      ..writeByte(2)
      ..write(obj.colorValue)
      ..writeByte(3)
      ..write(obj.size)
      ..writeByte(4)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveStrokeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
