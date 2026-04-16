import 'package:hive/hive.dart';
import 'package:studyfold/models/file_base.dart';
part 'quiz.g.dart';

@HiveType(typeId: 7)
class Quiz implements FileBase {
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
  int updatedAt;

  @override
  @HiveField(5)
  double positionX;

  @override
  @HiveField(6)
  double positionY;

  @HiveField(7)
  int page;

  @HiveField(8)
  List<String> options;

  Quiz({
    required this.id,
    required this.folderId,
    required this.title,
    required this.positionX,
    required this.positionY,
    required this.page,
    required this.options,
  }) : createdAt = DateTime.now().millisecondsSinceEpoch,
       updatedAt = DateTime.now().millisecondsSinceEpoch;

  @override
  Map<String, dynamic> toJson() {
    return {};
  }
  
  @override
  List<String> getAssetPaths() => [];
}
