// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_element.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CanvasElementAdapter extends TypeAdapter<CanvasElement> {
  @override
  final int typeId = 16;

  @override
  CanvasElement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CanvasElement(
      stroke: fields[0] as HiveStroke?,
      shape: fields[1] as HiveShape?,
      movableElement: fields[2] as MovableElementData?,
      children: (fields[3] as List?)?.cast<CanvasElement>(),
    );
  }

  @override
  void write(BinaryWriter writer, CanvasElement obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.stroke)
      ..writeByte(1)
      ..write(obj.shape)
      ..writeByte(2)
      ..write(obj.movableElement)
      ..writeByte(3)
      ..write(obj.children);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanvasElementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
