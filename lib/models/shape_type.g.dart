// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shape_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShapeTypeAdapter extends TypeAdapter<ShapeType> {
  @override
  final int typeId = 15;

  @override
  ShapeType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ShapeType.rectangle;
      case 1:
        return ShapeType.circle;
      case 2:
        return ShapeType.triangle;
      case 3:
        return ShapeType.line;
      default:
        return ShapeType.rectangle;
    }
  }

  @override
  void write(BinaryWriter writer, ShapeType obj) {
    switch (obj) {
      case ShapeType.rectangle:
        writer.writeByte(0);
        break;
      case ShapeType.circle:
        writer.writeByte(1);
        break;
      case ShapeType.triangle:
        writer.writeByte(2);
        break;
      case ShapeType.line:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShapeTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
