import 'package:flutter/widgets.dart';

class Stroke {
  final Color color;
  final double size;
  final Paint paint;
  final Path path;
  final Rect bounds;

  Stroke({
    required this.color, required this.size, required this.paint, required this.path
  }): bounds = _calculateBounds(path, paint);

  static Rect _calculateBounds(Path path, Paint paint) {
    return path.getBounds().inflate(paint.strokeWidth / 2);
  }
}