import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:studyfold/canvas_page.dart';
import 'package:studyfold/models/hive_shape.dart';
import 'package:studyfold/models/hive_stroke.dart';
import 'package:studyfold/models/shape_type.dart';

enum ActionType { draw, erase, addElement, resizeElement, deleteElement, modifyElement }

class StrokeRecord {
  final HiveStroke stroke;
  final int index;

  StrokeRecord(this.stroke, this.index);
}

class ShapeRecord {
  final HiveShape shape;
  final ShapeType type;
  final int index;

  ShapeRecord(this.shape, this.type, this.index);
}

class CanvasAction {
  final ActionType type;
  final List<StrokeRecord> strokes;
  final List<ShapeRecord> shapes;
  final Offset? shapeStartPoint;
  final Offset? shapeEndPoint;
  final Paint? paint;

  CanvasAction({
    required this.type,
    required this.strokes,
    required this.shapes,
    this.shapeStartPoint,
    this.shapeEndPoint,
    this.paint,
  });
}