// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_shape.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveShapeAdapter extends TypeAdapter<HiveShape> {
  @override
  final int typeId = 14;

  @override
  HiveShape read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveShape(
      id: fields[0] as String?,
      points: (fields[1] as List).cast<Offset>(),
      colorValue: fields[2] as int,
      size: fields[3] as double,
      type: fields[4] as ShapeType,
      shapeStartPoint: fields[5] as Offset,
      shapeEndPoint: fields[6] as Offset,
      rotation: fields[7] as double,
      config: fields[8] as ShapeConfig,
    );
  }

  @override
  void write(BinaryWriter writer, HiveShape obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.points)
      ..writeByte(2)
      ..write(obj.colorValue)
      ..writeByte(3)
      ..write(obj.size)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.shapeStartPoint)
      ..writeByte(6)
      ..write(obj.shapeEndPoint)
      ..writeByte(7)
      ..write(obj.rotation)
      ..writeByte(8)
      ..write(obj.config);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveShapeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
