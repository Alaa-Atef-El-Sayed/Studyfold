import 'package:hive/hive.dart';
import 'package:studyfold/models/file_base.dart';
part 'audio_file.g.dart';

@HiveType(typeId: 5)
class AudioFile implements FileBase {
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

  AudioFile({
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
    return {};
  }
  
  @override
  List<String> getAssetPaths() => [filePath];

}
