// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stroke_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StrokeTypeAdapter extends TypeAdapter<StrokeType> {
  @override
  final int typeId = 12;

  @override
  StrokeType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return StrokeType.pen;
      case 1:
        return StrokeType.highlighter;
      case 2:
        return StrokeType.dashed;
      default:
        return StrokeType.pen;
    }
  }

  @override
  void write(BinaryWriter writer, StrokeType obj) {
    switch (obj) {
      case StrokeType.pen:
        writer.writeByte(0);
        break;
      case StrokeType.highlighter:
        writer.writeByte(1);
        break;
      case StrokeType.dashed:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StrokeTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
