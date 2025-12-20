import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:studyfold/models/file_base.dart';
import 'package:studyfold/models/movable_element_data.dart';
import 'package:studyfold/stroke.dart';
part 'canvas.g.dart';

@HiveType(typeId: 9)
class Canvas implements FileBase{
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
  List<Stroke> strokes;

  Canvas({
    required this.id,
    required this.folderId,
    required this.name,
    required this.positionX,
    required this.positionY,
    required this.page,
    required this.strokes,
  }) : createdAt = DateTime.now().millisecondsSinceEpoch, 
       updatedAt = DateTime.now().millisecondsSinceEpoch;
}