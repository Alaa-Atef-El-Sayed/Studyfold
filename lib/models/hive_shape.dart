import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:studyfold/models/json_serializable.dart';
import 'package:studyfold/models/shape_config.dart';
import 'package:studyfold/models/shape_type.dart';
import 'package:uuid/uuid.dart';

part 'hive_shape.g.dart';

@HiveType(typeId: 14)
class HiveShape implements JsonSerializable {
  @HiveField(0)
  String? id;

  @HiveField(1)
  final List<Offset> points;

  @HiveField(2)
  int colorValue;

  @HiveField(3)
  final double size;

  @HiveField(4)
  ShapeType type;

  @HiveField(5)
  Offset shapeStartPoint;

  @HiveField(6)
  Offset shapeEndPoint;

  @HiveField(7)
  double rotation;

  @HiveField(8)
  ShapeConfig config;

  late final Path path;
  late final Paint paint;
  late final Rect bounds;

  HiveShape({
    this.id,
    this.points = const [],
    required this.colorValue,
    this.size = 0.0,
    required this.type,
    required this.shapeStartPoint,
    required this.shapeEndPoint,
    this.rotation = 0.0,
    this.config = const ShapeConfig(),
  }) {
    paint = _generatePaint();
    path = _generatePath();
    bounds = _calculateBounds();
    id = id ?? const Uuid().v4();
  }

  // @override
  // Map<String, dynamic> toJson() {
  //   return {
  //     'id': id,
  //     'colorValue': colorValue,
  //     'type': type.name,
  //     'shapeStartPoint': shapeStartPoint.toString(),
  //     'shapeEndPoint': shapeEndPoint.toString(),
  //     'rotation': rotation,
  //     'config': config.toJson(),
  //   };
  // }

  @override
Map<String, dynamic> toJson() {
  return {
    'id': id,
    'colorValue': colorValue,
    'type': type.name,
    'startPoint': [shapeStartPoint.dx, shapeStartPoint.dy],
    'endPoint': [shapeEndPoint.dx, shapeEndPoint.dy],
    'rotation': rotation,
    'config': config.toJson(),
  };
}

factory HiveShape.fromJson(Map<String, dynamic> json) {
  final startList = json['startPoint'] as List;
  final endList = json['endPoint'] as List;

  return HiveShape(
    id: const Uuid().v4(),
    colorValue: json['colorValue'] as int,
    shapeStartPoint: Offset((startList[0] as num).toDouble(), (startList[1] as num).toDouble()),
    shapeEndPoint: Offset((endList[0] as num).toDouble(), (endList[1] as num).toDouble()),
    rotation: (json['rotation'] as num).toDouble(),
    config: ShapeConfig.fromJson(json['config']),
    type: ShapeType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => ShapeType.rectangle,
    ),
  );
}

  Paint _generatePaint() {
    final basePaint = Paint()
      ..color = Color(colorValue)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    return basePaint..strokeWidth = size;
  }

  Path _generatePath() {
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points[0].dx, points[0].dy);

    if (points.length < 2) {
      path.addOval(Rect.fromCircle(center: points[0], radius: 1.0));
    } else {
      for (int i = 1; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        path.quadraticBezierTo(
          p0.dx,
          p0.dy,
          (p0.dx + p1.dx) / 2,
          (p0.dy + p1.dy) / 2,
        );
      }
    }
    return path;
  }

  Rect _calculateBounds() {
    return path.getBounds().inflate(size / 2);
  }
}
