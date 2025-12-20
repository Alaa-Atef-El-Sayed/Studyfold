// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FolderAdapter extends TypeAdapter<Folder> {
  @override
  final int typeId = 0;

  @override
  Folder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Folder(
      id: fields[0] as String,
      name: fields[2] as String,
      folderId: fields[1] as String,
      positionX: fields[6] as double,
      positionY: fields[7] as double,
      page: fields[8] as int,
      pages: fields[9] as int,
      description: fields[4] as String?,
      color: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Folder obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.folderId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.color)
      ..writeByte(6)
      ..write(obj.positionX)
      ..writeByte(7)
      ..write(obj.positionY)
      ..writeByte(8)
      ..write(obj.page)
      ..writeByte(9)
      ..write(obj.pages);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FolderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
