// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 1;

  @override
  Note read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Note(
      id: fields[0] as String,
      folderId: fields[1] as String,
      title: fields[2] as String,
      document: (fields[5] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      positionX: fields[8] as double,
      positionY: fields[9] as double,
      page: fields[10] as int,
      movableElements: (fields[6] as List).cast<MovableElementData>(),
      tags: (fields[7] as List).cast<String>(),
    )..updatedAt = fields[4] as int;
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.folderId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.document)
      ..writeByte(6)
      ..write(obj.movableElements)
      ..writeByte(7)
      ..write(obj.tags)
      ..writeByte(8)
      ..write(obj.positionX)
      ..writeByte(9)
      ..write(obj.positionY)
      ..writeByte(10)
      ..write(obj.page);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
