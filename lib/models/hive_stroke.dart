import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:studyfold/models/json_serializable.dart';
import 'package:studyfold/models/stroke_type.dart';
import 'package:uuid/uuid.dart';

part 'hive_stroke.g.dart';

@HiveType(typeId: 11)
class HiveStroke implements JsonSerializable {
  @HiveField(0)
  String? id;

  @HiveField(1)
  final List<Offset> points;

  @HiveField(2)
  final int colorValue;

  @HiveField(3)
  final double size;

  @HiveField(4)
  StrokeType type;

  late final Path path;
  late final Paint paint;
  late final Rect bounds;

  HiveStroke({
    this.id,
    required this.points,
    required this.colorValue,
    required this.size,
    required this.type,
  }) {
    paint = _generatePaint();
    path = _generatePath();
    bounds = _calculateBounds();
    id = id ?? const Uuid().v4();
  }

  @override
  Map<String, dynamic> toJson() {
  List<double> flatPoints = [];
  for (var p in points) {
    flatPoints.add(p.dx);
    flatPoints.add(p.dy);
  }

  return {
    'color': colorValue,
    'size': size,
    'points': flatPoints,
    'type': type.name
  };
}

factory HiveStroke.fromJson(Map<String, dynamic> json) {
  final List<dynamic> flatPoints = json['points'] as List;
  final List<Offset> reconstructedPoints = [];
  
  for (int i = 0; i < flatPoints.length; i += 2) {
    reconstructedPoints.add(
      Offset(
        (flatPoints[i] as num).toDouble(), 
        (flatPoints[i + 1] as num).toDouble()
      )
    );
  }

  return HiveStroke(
    id: const Uuid().v4(),
    colorValue: json['color'] as int,
    size: (json['size'] as num).toDouble(),
    points: reconstructedPoints,
    type: StrokeType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => StrokeType.pen,
    ),
  );
}

  Paint _generatePaint() {
    final basePaint = Paint()
      ..color = Color(colorValue)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (type) {
      case StrokeType.pen:
        return basePaint..strokeWidth = size;

      case StrokeType.highlighter:
        return basePaint
          ..strokeWidth = 30.0
          ..color = Color(colorValue).withValues(alpha: 0.4)
          ..strokeCap = StrokeCap.square
          ..blendMode = BlendMode.multiply;

      case StrokeType.dashed:
        return basePaint
          ..strokeWidth = size
          ..color = Color(colorValue);

      default:
        return basePaint..strokeWidth = size;
    }
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
