import 'package:hive/hive.dart';
import 'package:studyfold/models/file_base.dart';
part 'folder.g.dart';

@HiveType(typeId: 0)
class Folder implements FileBase {
  @override
  @HiveField(0)
  final String id;

  @override
  @HiveField(1)
  String folderId;

  @HiveField(2)
  String name;

  @override
  @HiveField(3)
  final int createdAt;

  @HiveField(4)
  String? description;

  @HiveField(5)
  String color;

  @override
  @HiveField(6)
  double positionX;

  @override
  @HiveField(7)
  double positionY;

  @HiveField(8)
  int page;

  @HiveField(9)
  int pages;

  Folder({
    required this.id,
    required this.name,
    required this.folderId,
    required this.positionX,
    required this.positionY,
    required this.page,
    required this.pages,
    this.description,
    this.color = "#2196F3",
  }) : createdAt = DateTime.now().millisecondsSinceEpoch;

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'folder',
      'id': id,
      'folderId': folderId,
      'name': name,
      'description': description,
      'color': color,
      'positionX': positionX,
      'positionY': positionY,
      'page': page,
      'pages': pages,
    };
  }

  factory Folder.fromJson({required Map<String, dynamic> json, required String folderId, required String id}) {
    return Folder(
      id: id,
      folderId: folderId,
      name: json['name'],
      description: json['description'],
      color: json['color'],
      positionX: json['positionX'],
      positionY: json['positionY'],
      page: json['page'],
      pages: json['pages'],
    );
  }

  @override
  List<String> getAssetPaths() => [];
}
