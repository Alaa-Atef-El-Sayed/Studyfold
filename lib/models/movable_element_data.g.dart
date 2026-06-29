// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movable_element_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MovableElementDataAdapter extends TypeAdapter<MovableElementData> {
  @override
  final int typeId = 2;

  @override
  MovableElementData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MovableElementData(
      id: fields[0] as String,
      type: fields[1] as ElementType,
      positionX: fields[2] as double,
      positionY: fields[3] as double,
      width: fields[4] as double,
      height: fields[5] as double,
      filePath: fields[6] as String,
      aspectRatio: fields[8] as double?,
      rotation: fields[9] as double,
      originalWidth: fields[10] as double,
      originalHeight: fields[11] as double,
      cropRectStart: fields[12] as Offset,
      cropRectEnd: fields[13] as Offset,
      title: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MovableElementData obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.positionX)
      ..writeByte(3)
      ..write(obj.positionY)
      ..writeByte(4)
      ..write(obj.width)
      ..writeByte(5)
      ..write(obj.height)
      ..writeByte(6)
      ..write(obj.filePath)
      ..writeByte(7)
      ..write(obj.title)
      ..writeByte(8)
      ..write(obj.aspectRatio)
      ..writeByte(9)
      ..write(obj.rotation)
      ..writeByte(10)
      ..write(obj.originalWidth)
      ..writeByte(11)
      ..write(obj.originalHeight)
      ..writeByte(12)
      ..write(obj.cropRectStart)
      ..writeByte(13)
      ..write(obj.cropRectEnd);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MovableElementDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
