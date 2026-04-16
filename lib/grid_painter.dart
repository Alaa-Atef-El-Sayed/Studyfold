import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

      // final double startX = (viewport.left / gridSize).floor() * gridSize;
    // final double startY = (viewport.top / gridSize).floor() * gridSize;

    // for (double x = startX; x <= viewport.right; x += gridSize) {
    //   canvas.drawLine(
    //     Offset(x, viewport.top),
    //     Offset(x, viewport.bottom),
    //     gridPaint,
    //   );
    // }

    // for (double y = startY; y <= viewport.bottom; y += gridSize) {
    //   canvas.drawLine(
    //     Offset(viewport.left, y),
    //     Offset(viewport.right, y),
    //     gridPaint,
    //   );
    // }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}