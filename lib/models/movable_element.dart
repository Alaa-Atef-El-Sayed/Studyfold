import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:studyfold/models/movable_element_data.dart';
import 'package:studyfold/models/element_type.dart';

class MovableElement {
  final String id;
  final ElementType type;
  Widget widget;
  Offset position;
  final String? filePath;
  final String? title;
  final double? aspectRatio;
  double width;
  double height;
  double rotation;

  MovableElement({
    required this.id,
    required this.type,
    required this.widget,
    required this.position,
    this.aspectRatio,
    this.filePath,
    this.title,
    required this.width,
    required this.height,
    this.rotation = 0.0,
  });

  MovableElementData toData() {
    return MovableElementData(
      id: id,
      type: type,
      positionX: position.dx,
      positionY: position.dy,
      width: width,
      height: height,
      aspectRatio: aspectRatio,
      rotation: rotation,
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
      aspectRatio: data.aspectRatio,
      rotation: data.rotation,
      filePath: data.filePath,
      title: data.title,
    );
  }

  bool contains(Offset point) {
    final localPoint = toLocalPoint(point);
    final rect = Rect.fromLTWH(position.dx, position.dy, width, height);
    return rect.contains(localPoint);
  }

  bool containsDelete(Offset point) {
    final localPoint = toLocalPoint(point);
    final center = Offset(position.dx + width - 5, position.dy + 5);
    return (localPoint - center).distance <= 30.0;
  }

  bool containsResize(Offset point) {
    final localPoint = toLocalPoint(point);
    final center = Offset(position.dx + width - 5, position.dy + height - 5);
    return (localPoint - center).distance <= 30.0;
  }

  bool containsRotate(Offset point) {
    final localPoint = toLocalPoint(point);
    final center = Offset(position.dx + 5, position.dy + height - 5);
    return (localPoint - center).distance <= 30.0;
  }

  void open(BuildContext context) async {
    switch (type) {
      case ElementType.document:
        try {
          final result = await OpenFile.open(filePath, type: 'application/pdf');

          switch (result.type) {
            case ResultType.done:
              // Successfully opened
              break;
            case ResultType.noAppToOpen:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Found no apps that can open that file'),
                ),
              );
              break;
            case ResultType.fileNotFound:
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('PDF file not found')));
              break;
            case ResultType.permissionDenied:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Permission denied to open PDF')),
              );
              break;
            case ResultType.error:
            default:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${result.message}')),
              );
          }
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to open PDF: $e')));
        }
        break;
      default:
    }
  }

  Offset getCorners() {
    final center = Offset(position.dx + width / 2, position.dy + height / 2);

    final double dx = -width / 2;
    final double dy = -height / 2;

    final double cosTheta = Math.cos(rotation);
    final double sinTheta = Math.sin(rotation);

    final double rotatedX = dx * cosTheta - dy * sinTheta;
    final double rotatedY = dx * sinTheta + dy * cosTheta;

    return center + Offset(rotatedX, rotatedY);
  }

  Offset toLocalPoint(Offset globalPoint) {
    final center = Offset(position.dx + width / 2, position.dy + height / 2);

    final dx = globalPoint.dx - center.dx;
    final dy = globalPoint.dy - center.dy;

    final cosTheta = Math.cos(-rotation);
    final sinTheta = Math.sin(-rotation);

    final newDx = dx * cosTheta - dy * sinTheta;
    final newDy = dx * sinTheta + dy * cosTheta;

    return Offset(center.dx + newDx, center.dy + newDy);
  }
}
