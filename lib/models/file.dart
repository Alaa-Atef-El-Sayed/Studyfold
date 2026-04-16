import 'package:hive/hive.dart';
import 'package:studyfold/models/json_serializable.dart';

part 'file.g.dart';

@HiveType(typeId: 13)
class HiveFile implements JsonSerializable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String parentId;

  @HiveField(2)
  final String filepath;

  HiveFile({required this.id, required this.parentId, required this.filepath});

  Map<String, dynamic> toJson({String? exportFileName}) {
    return {
      'id': id,
      'parentId': parentId,
      'filepath': exportFileName ?? filepath,
    };
  }

  factory HiveFile.fromJson(
    Map<String, dynamic> json, {
    required String newAbsolutePath,
  }) {
    return HiveFile(
      id: json['id'],
      parentId: json['parentId'],
      filepath: newAbsolutePath,
    );
  }
}
