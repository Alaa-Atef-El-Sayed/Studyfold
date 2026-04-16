import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class PatternFactory {
  static Future<ui.Image> createGridPattern({
    required double spacing,
    required Color color,
    bool isDot = false,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    if (isDot) {
      canvas.drawCircle(Offset(spacing / 2, spacing / 2), 1.5, paint);
    } else {
      canvas.drawLine(Offset(0, 0), Offset(spacing, 0), paint);
      canvas.drawLine(Offset(0, 0), Offset(0, spacing), paint);
    }

    final picture = recorder.endRecording();
    return picture.toImage(spacing.toInt(), spacing.toInt());
  }
}