// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shape_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShapeConfigAdapter extends TypeAdapter<ShapeConfig> {
  @override
  final int typeId = 17;

  @override
  ShapeConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShapeConfig(
      shapeType: fields[0] as ShapeType,
      drawFromCenter: fields[1] as bool,
      lockAspectRatio: fields[2] as bool,
      borderRadius: fields[3] as double,
      fill: fields[4] as bool,
      borderWidth: fields[5] as double,
      borderColorValue: fields[6] as int,
      isLocked: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ShapeConfig obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.shapeType)
      ..writeByte(1)
      ..write(obj.drawFromCenter)
      ..writeByte(2)
      ..write(obj.lockAspectRatio)
      ..writeByte(3)
      ..write(obj.borderRadius)
      ..writeByte(4)
      ..write(obj.fill)
      ..writeByte(5)
      ..write(obj.borderWidth)
      ..writeByte(6)
      ..write(obj.borderColorValue)
      ..writeByte(7)
      ..write(obj.isLocked);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShapeConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
