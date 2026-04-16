// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveFileAdapter extends TypeAdapter<HiveFile> {
  @override
  final int typeId = 13;

  @override
  HiveFile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveFile(
      id: fields[0] as String,
      parentId: fields[1] as String,
      filepath: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HiveFile obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.parentId)
      ..writeByte(2)
      ..write(obj.filepath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveFileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
