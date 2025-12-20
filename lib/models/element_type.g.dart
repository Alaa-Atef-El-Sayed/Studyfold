// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'element_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ElementTypeAdapter extends TypeAdapter<ElementType> {
  @override
  final int typeId = 3;

  @override
  ElementType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ElementType.image;
      case 1:
        return ElementType.audio;
      case 2:
        return ElementType.document;
      case 3:
        return ElementType.text;
      default:
        return ElementType.image;
    }
  }

  @override
  void write(BinaryWriter writer, ElementType obj) {
    switch (obj) {
      case ElementType.image:
        writer.writeByte(0);
        break;
      case ElementType.audio:
        writer.writeByte(1);
        break;
      case ElementType.document:
        writer.writeByte(2);
        break;
      case ElementType.text:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ElementTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
