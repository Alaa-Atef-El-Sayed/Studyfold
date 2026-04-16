import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:studyfold/models/element_type.dart';
import 'package:studyfold/models/json_serializable.dart';
part 'movable_element_data.g.dart';

@HiveType(typeId: 2)
class MovableElementData implements JsonSerializable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final ElementType type;

  @HiveField(2)
  final double positionX;

  @HiveField(3)
  final double positionY;

  @HiveField(4)
  final double width;

  @HiveField(5)
  final double height;

  @HiveField(6)
  final String filePath;

  @HiveField(7)
  final String? title;

  @HiveField(8)
  final double? aspectRatio;

  @HiveField(9)
  final double rotation;

  MovableElementData({
    required this.id,
    required this.type,
    required this.positionX,
    required this.positionY,
    required this.width,
    required this.height,
    required this.filePath,
    required this.aspectRatio,
    required this.rotation,
    this.title,
  });

  Offset get position => Offset(positionX, positionY);

  @override
  Map<String, dynamic> toJson(){
    return {
      'id': id,
      'type': type,
      'positionX': positionX,
      'positionY': positionY,
      'width': width,
      'height': height,
      'filePath': '',
      'title': title,
      'aspectRatio': aspectRatio,
      'rotation': rotation,
    };
  }
}
