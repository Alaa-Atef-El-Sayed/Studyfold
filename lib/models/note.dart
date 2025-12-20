import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:studyfold/models/file_base.dart';
import 'package:studyfold/models/movable_element_data.dart';
part 'note.g.dart';

@HiveType(typeId: 1)
class Note implements FileBase{
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
  
  @HiveField(5)
  List<Map<String, dynamic>> document;
  
  @HiveField(6)
  List<MovableElementData> movableElements;
  
  @HiveField(7)
  List<String> tags;

  @override
  @HiveField(8)
  double positionX;
  
  @override
  @HiveField(9)
  double positionY;
  
  @HiveField(10)
  int page;

  Note({
    required this.id,
    required this.folderId,
    required this.title,
    required this.document,
    required this.positionX,
    required this.positionY,
    required this.page,
    this.movableElements = const [],
    this.tags = const [],
  }) : createdAt = DateTime.now().millisecondsSinceEpoch, 
       updatedAt = DateTime.now().millisecondsSinceEpoch;
}