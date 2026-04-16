import 'package:hive/hive.dart';
import 'package:studyfold/models/canvas_element.dart';
import 'package:studyfold/models/file_base.dart';
import 'package:studyfold/models/hive_stroke.dart';
import 'package:studyfold/models/movable_element_data.dart';

part 'canvas.g.dart';

@HiveType(typeId: 9)
class Canvas implements FileBase {
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
  List<HiveStroke> strokes;

  @HiveField(9)
  List<MovableElementData> images;

  @HiveField(10)
  List<MovableElementData> documents;

  @HiveField(11)
  List<MovableElementData> audioFiles;

  @HiveField(12)
  List<CanvasElement> elements;

  Canvas({
    required this.id,
    required this.folderId,
    required this.name,
    required this.positionX,
    required this.positionY,
    required this.page,
    required this.strokes,
    this.elements = const [],
    this.images = const [],
    this.documents = const [],
    this.audioFiles = const [],
  }) : createdAt = DateTime.now().millisecondsSinceEpoch,
       updatedAt = DateTime.now().millisecondsSinceEpoch;

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'canvas',
      'id': id,
      'folderId': folderId,
      'name': name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'positionX': positionX,
      'positionY': positionY,
      'page': page,
      'images': images.map((image) => image.toJson()).toList(),
      'documents': documents.map((document) => document.toJson()).toList(),
      'audioFiles': '',
      'elements': elements.map((element) => element.toJson()).toList(),
    };
  }

  factory Canvas.fromJson({
    required Map<String, dynamic> json,
    required String assetsDirPath,
    required String folderId,
    required String id,
  }) {
    return Canvas(
      id: id,
      folderId: folderId,
      name: json['name'] ?? 'Untitled',
      positionX: (json['positionX'] as num?)?.toDouble() ?? 0.0,
      positionY: (json['positionY'] as num?)?.toDouble() ?? 0.0,
      page: json['page'] ?? 1,
      // createdAt: json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      // updatedAt: json['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,

      elements: (json['elements'] as List? ?? [])
          .map(
            (element) => CanvasElement.fromJson(
              json: element,
              assetsDirPath: assetsDirPath,
            ),
          )
          .toList(),

      // (Parse images and documents here later)
      strokes: [],
    );
  }

  @override
  List<String> getAssetPaths() => [];
}
