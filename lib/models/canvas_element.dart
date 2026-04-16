import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:studyfold/models/hive_shape.dart';
import 'package:studyfold/models/hive_stroke.dart';
import 'package:studyfold/models/json_serializable.dart';
import 'package:studyfold/models/movable_element_data.dart';
import 'package:studyfold/models/shape_type.dart';

part 'canvas_element.g.dart';

@HiveType(typeId: 16)
class CanvasElement extends HiveObject implements JsonSerializable{
  @HiveField(0)
  final HiveStroke? stroke;

  @HiveField(1)
  final HiveShape? shape;

  @HiveField(2)
  final MovableElementData? movableElement;

  @HiveField(3)
  List<CanvasElement> children;

  CanvasElement({
    this.stroke,
    this.shape,
    this.movableElement,
    List<CanvasElement>? children,
  }) : children = children ?? [];

  @override
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    // 💡 Only add the key if the object exists. This keeps JSON tiny!
    if (stroke != null) map['stroke'] = stroke!.toJson();
    if (shape != null) map['shape'] = shape!.toJson();
    //  map['children'] = children.map((e) => e.toJson()).toList();

    // Future proofing:
    // if (image != null) map['image'] = image!.toJson();

    return map;
  }

  factory CanvasElement.fromJson({
    required Map<String, dynamic> json,
    required String assetsDirPath, // Ready for when you add images!
  }) {
    return CanvasElement(
      // We check if the key exists in the map
      stroke: json.containsKey('stroke')
          ? HiveStroke.fromJson(json['stroke'])
          : null,
      shape: json.containsKey('shape')
          ? HiveShape.fromJson(json['shape'])
          : null,

      // children: json.containsKey('children')
      //     ? (json['children'] as List)
      //           .map(
      //             (e) => CanvasElement.fromJson(
      //               json: e,
      //               assetsDirPath: assetsDirPath,
      //             ),
      //           )
      //           .toList()
      //     : [],
    );
  }

  Rect _getShapeBounds() {
    if (shape == null) return Rect.zero;
    Rect initialRect = Rect.fromPoints(
      shape!.shapeStartPoint,
      shape!.shapeEndPoint,
    );
    // if (shape!.type == ShapeType.circle) {
    //   return Rect.fromCircle(
    //     center: initialRect.center,
    //     radius: (shape!.shapeEndPoint - shape!.shapeStartPoint).distance / 2,
    //   ).inflate(4);
    // }
    return initialRect;
  }

  Offset _toLocalPoint(Offset globalPoint, Rect bounds) {
    double rotation = shape!.rotation;

    if (rotation == 0) return globalPoint;

    final center = bounds.center;
    final dx = globalPoint.dx - center.dx;
    final dy = globalPoint.dy - center.dy;

    final cosTheta = math.cos(-rotation);
    final sinTheta = math.sin(-rotation);

    final newDx = dx * cosTheta - dy * sinTheta;
    final newDy = dx * sinTheta + dy * cosTheta;

    return Offset(center.dx + newDx, center.dy + newDy);
  }

  bool contains(Offset point) {
    if (shape == null) return false;
    final bounds = _getShapeBounds();
    final localPoint = _toLocalPoint(point, bounds);

    if (shape!.type == ShapeType.circle) {
      final center = bounds.center;
      final rx = bounds.width / 2;
      final ry = bounds.height / 2;

      if (rx == 0 || ry == 0) return false;

      final dx = localPoint.dx - center.dx;
      final dy = localPoint.dy - center.dy;

      return ((dx * dx) / (rx * rx) + (dy * dy) / (ry * ry)) <= 1.0;
    }

    return bounds.contains(localPoint);
  }

  bool containsDelete(Offset point, double scale) {
    if (shape == null) return false;
    final bounds = _getShapeBounds();
    final localPoint = _toLocalPoint(point, bounds);

    final handleCenter = Offset(
      bounds.right + 20 / scale,
      bounds.top - 20 / scale,
    );

    return (localPoint - handleCenter).distance <= 20.0 / scale;
  }

  bool containsResize(Offset point, double scale) {
    if (shape == null) return false;
    final bounds = _getShapeBounds();
    final localPoint = _toLocalPoint(point, bounds);

    final handleCenter = Offset(
      bounds.right + 20 / scale,
      bounds.bottom + 20 / scale,
    );

    return (localPoint - handleCenter).distance <= 20.0 / scale;
  }

  bool containsRotate(Offset point, double scale) {
    if (shape == null) return false;
    final bounds = _getShapeBounds();
    final localPoint = _toLocalPoint(point, bounds);

    final handleCenter = Offset(
      bounds.left - 20 / scale,
      bounds.bottom + 20 / scale,
    );

    return (localPoint - handleCenter).distance <= 20.0 / scale;
  }
}
