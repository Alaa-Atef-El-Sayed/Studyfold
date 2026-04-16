import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:studyfold/models/file_base.dart';
part 'pdf.g.dart';

@HiveType(typeId: 4)
class Pdf implements FileBase {
  @override
  @HiveField(0)
  final String id;

  @override
  @HiveField(1)
  String folderId;

  @HiveField(2)
  String title;

  @override
  @HiveField(3)
  final int createdAt;

  @HiveField(4)
  final String filePath;

  @HiveField(5)
  List<String> tags;

  @override
  @HiveField(6)
  double positionX;

  @override
  @HiveField(7)
  double positionY;

  @HiveField(8)
  int page;

  Pdf({
    required this.id,
    required this.folderId,
    required this.title,
    required this.filePath,
    required this.positionX,
    required this.positionY,
    required this.page,
    this.tags = const [],
  }) : createdAt = DateTime.now().millisecondsSinceEpoch;

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'pdf',
      'id': id,
      'folderId': folderId,
      'title': title,
      'filepath': filePath.split('/').last,
      'tags': tags,
      'positionX': positionX,
      'positionY': positionY,
      'page': page,
    };
  }

  factory Pdf.fromJson({required Map<String, dynamic> json,required String assetsDirPath, required String folderId, required String id}) {
    return Pdf(
      id: id,
      folderId: folderId,
      title: json['title'],
      positionX: json['positionX'],
      positionY: json['positionY'],
      page: json['page'],
      filePath: '$assetsDirPath/${json['filepath']}',
    );
  }

  @override
  List<String> getAssetPaths() => [filePath];
}
