import 'package:flutter/material.dart';
import 'package:studyfold/models/movable_element_data.dart';
import 'package:studyfold/models/element_type.dart';

class MovableElement {
  final String id;
  final ElementType type;
  Widget widget;
  Offset position;
  final String? filePath;
  final String? title;
  double width;
  double height;

  MovableElement({
    required this.id,
    required this.type,
    required this.widget,
    required this.position,
    this.filePath,
    this.title,
    required this.width,
    required this.height,
  });

   MovableElementData toData() {
    return MovableElementData(
      id: id,
      type: type,
      positionX: position.dx,
      positionY: position.dy,
      width: width,
      height: height,
      filePath: filePath ?? '',
      title: title,
    );
  }

  factory MovableElement.fromData(MovableElementData data, Widget widget) {
    return MovableElement(
      id: data.id,
      type: data.type,
      widget: widget,
      position: data.position,
      width: data.width,
      height: data.height,
      filePath: data.filePath,
      title: data.title,
    );
  }
}