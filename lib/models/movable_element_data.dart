import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:studyfold/models/element_type.dart';
part 'movable_element_data.g.dart';

@HiveType(typeId: 2)
class MovableElementData {
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

  MovableElementData({
    required this.id,
    required this.type,
    required this.positionX,
    required this.positionY,
    required this.width,
    required this.height,
    required this.filePath,
    this.title,
  });

  Offset get position => Offset(positionX, positionY);
}