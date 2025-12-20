// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CanvasAdapter extends TypeAdapter<Canvas> {
  @override
  final int typeId = 9;

  @override
  Canvas read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Canvas(
      id: fields[0] as String,
      folderId: fields[1] as String,
      name: fields[2] as String,
      positionX: fields[5] as double,
      positionY: fields[6] as double,
      page: fields[7] as int,
      strokes: (fields[8] as List).cast<Stroke>(),
    )..updatedAt = fields[4] as int;
  }

  @override
  void write(BinaryWriter writer, Canvas obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.folderId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.positionX)
      ..writeByte(6)
      ..write(obj.positionY)
      ..writeByte(7)
      ..write(obj.page)
      ..writeByte(8)
      ..write(obj.strokes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanvasAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
