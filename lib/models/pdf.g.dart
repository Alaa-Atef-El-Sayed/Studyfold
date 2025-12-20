// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdf.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PdfAdapter extends TypeAdapter<Pdf> {
  @override
  final int typeId = 4;

  @override
  Pdf read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Pdf(
      id: fields[0] as String,
      folderId: fields[1] as String,
      title: fields[2] as String,
      filePath: fields[4] as String,
      positionX: fields[6] as double,
      positionY: fields[7] as double,
      page: fields[8] as int,
      tags: (fields[5] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Pdf obj) {
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
      ..write(obj.filePath)
      ..writeByte(5)
      ..write(obj.tags)
      ..writeByte(6)
      ..write(obj.positionX)
      ..writeByte(7)
      ..write(obj.positionY)
      ..writeByte(8)
      ..write(obj.page);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
