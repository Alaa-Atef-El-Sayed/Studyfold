// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuizAdapter extends TypeAdapter<Quiz> {
  @override
  final int typeId = 7;

  @override
  Quiz read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Quiz(
      id: fields[0] as String,
      folderId: fields[1] as String,
      title: fields[2] as String,
      positionX: fields[5] as double,
      positionY: fields[6] as double,
      page: fields[7] as int,
      options: (fields[8] as List).cast<String>(),
    )..updatedAt = fields[4] as int;
  }

  @override
  void write(BinaryWriter writer, Quiz obj) {
    writer
      ..writeByte(9)
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
      ..write(obj.positionX)
      ..writeByte(6)
      ..write(obj.positionY)
      ..writeByte(7)
      ..write(obj.page)
      ..writeByte(8)
      ..write(obj.options);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
