import 'package:flutter/material.dart';

class CropOverlay extends StatefulWidget {
  final Size imageSize;
  final Rect initialCropRect;
  final ValueChanged<Rect> onCropChanged;
  final double inverseScale;

  const CropOverlay({
    super.key,
    required this.imageSize,
    required this.initialCropRect,
    required this.onCropChanged,
    required this.inverseScale,
  });

  @override
  State<CropOverlay> createState() => _CropOverlayState();
}

class _CropOverlayState extends State<CropOverlay> {
  late Rect _cropRect;
  final double _minSize = 50.0;
  double _handleHitSize = 40.0; // Invisible touch target size

  @override
  void initState() {
    super.initState();
    _cropRect = widget.initialCropRect;
  }

  @override
  void didUpdateWidget(covariant CropOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCropRect != widget.initialCropRect) {
      _cropRect = widget.initialCropRect;
    }
  }

  // 💡 This single function handles all 8 edges and corners dynamically!
  void _handleDrag(
    Offset delta, {
    bool top = false,
    bool bottom = false,
    bool left = false,
    bool right = false,
  }) {
    setState(() {
      double newTop = _cropRect.top + (top ? delta.dy : 0);
      double newBottom = _cropRect.bottom + (bottom ? delta.dy : 0);
      double newLeft = _cropRect.left + (left ? delta.dx : 0);
      double newRight = _cropRect.right + (right ? delta.dx : 0);

      // Clamp to Minimum Size
      if (newBottom - newTop < _minSize) {
        if (top) newTop = newBottom - _minSize;
        if (bottom) newBottom = newTop + _minSize;
      }
      if (newRight - newLeft < _minSize) {
        if (left) newLeft = newRight - _minSize;
        if (right) newRight = newLeft + _minSize;
      }

      // Clamp to Image Bounds
      newTop = newTop.clamp(0.0, widget.imageSize.height);
      newBottom = newBottom.clamp(0.0, widget.imageSize.height);
      newLeft = newLeft.clamp(0.0, widget.imageSize.width);
      newRight = newRight.clamp(0.0, widget.imageSize.width);

      _cropRect = Rect.fromLTRB(newLeft, newTop, newRight, newBottom);
    });

    widget.onCropChanged(_cropRect);
  }

  void _handleCenterDrag(Offset delta) {
    setState(() {
      // Move the whole rect, keeping size intact, clamped to edges
      Offset newCenter = _cropRect.center + delta;

      double safeX = newCenter.dx.clamp(
        _cropRect.width / 2,
        widget.imageSize.width - _cropRect.width / 2,
      );
      double safeY = newCenter.dy.clamp(
        _cropRect.height / 2,
        widget.imageSize.height - _cropRect.height / 2,
      );

      _cropRect = Rect.fromCenter(
        center: Offset(safeX, safeY),
        width: _cropRect.width,
        height: _cropRect.height,
      );
    });
    widget.onCropChanged(_cropRect);
  }

  @override
  Widget build(BuildContext context) {
    _handleHitSize = 40 * widget.inverseScale;
    return Stack(
      children: [
        // 1. The Dark Overlay and White Border
        CustomPaint(
          size: widget.imageSize,
          painter: CropMaskPainter(_cropRect, widget.inverseScale),
        ),

        // 2. Center Draggable Area (Moves the whole box)
        Positioned.fromRect(
          rect: _cropRect.deflate(_handleHitSize / 2), // Keep away from edges
          child: GestureDetector(
            onPanUpdate: (d) => _handleCenterDrag(d.delta),
            child: Container(color: Colors.transparent),
          ),
        ),

        // 3. The 8 Drag Handles
        ..._buildHandles(),
      ],
    );
  }

  List<Widget> _buildHandles() {
    return [
      // Corners
      _buildHandle(
        left: _cropRect.left,
        top: _cropRect.top,
        onDrag: (d) => _handleDrag(d, top: true, left: true),
      ),
      _buildHandle(
        left: _cropRect.right,
        top: _cropRect.top,
        onDrag: (d) => _handleDrag(d, top: true, right: true),
      ),
      _buildHandle(
        left: _cropRect.left,
        top: _cropRect.bottom,
        onDrag: (d) => _handleDrag(d, bottom: true, left: true),
      ),
      _buildHandle(
        left: _cropRect.right,
        top: _cropRect.bottom,
        onDrag: (d) => _handleDrag(d, bottom: true, right: true),
      ),

      // Edges (Centered between corners)
      _buildHandle(
        left: _cropRect.center.dx,
        top: _cropRect.top,
        onDrag: (d) => _handleDrag(d, top: true),
      ),
      _buildHandle(
        left: _cropRect.center.dx,
        top: _cropRect.bottom,
        onDrag: (d) => _handleDrag(d, bottom: true),
      ),
      _buildHandle(
        left: _cropRect.left,
        top: _cropRect.center.dy,
        onDrag: (d) => _handleDrag(d, left: true),
      ),
      _buildHandle(
        left: _cropRect.right,
        top: _cropRect.center.dy,
        onDrag: (d) => _handleDrag(d, right: true),
      ),
    ];
  }

  Widget _buildHandle({
    required double left,
    required double top,
    required Function(Offset) onDrag,
  }) {
    return Positioned(
      left: left - (_handleHitSize / 2),
      top: top - (_handleHitSize / 2),
      child: GestureDetector(
        onPanUpdate: (details) => onDrag(details.delta),
        child: Container(
          width: _handleHitSize,
          height: _handleHitSize,
          color: Colors
              .transparent, // 💡 Change to Colors.red.withOpacity(0.5) to debug handle positions!
        ),
      ),
    );
  }
}

class CropMaskPainter extends CustomPainter {
  final Rect cropRect;
  final double inverseScale;

  CropMaskPainter(this.cropRect, this.inverseScale);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw the dark overlay
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black87.withOpacity(0.6),
    );

    // 2. Punch the transparent hole!
    canvas.drawRect(cropRect, Paint()..blendMode = BlendMode.clear);
    canvas.restore();

    // 3. Draw the white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * inverseScale;
    canvas.drawRect(cropRect, borderPaint);

    // 4. (Optional) Draw thick corner indicators (Like iOS/Android)
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 * inverseScale;

    final double l = 15.0 * inverseScale; // Length of the corner ticks
    final Path path = Path()
      // Top Left
      ..moveTo(cropRect.left, cropRect.top + l)
      ..lineTo(cropRect.left, cropRect.top)
      ..lineTo(cropRect.left + l, cropRect.top)
      // Top Right
      ..moveTo(cropRect.right - l, cropRect.top)
      ..lineTo(cropRect.right, cropRect.top)
      ..lineTo(cropRect.right, cropRect.top + l)
      // Bottom Right
      ..moveTo(cropRect.right, cropRect.bottom - l)
      ..lineTo(cropRect.right, cropRect.bottom)
      ..lineTo(cropRect.right - l, cropRect.bottom)
      // Bottom Left
      ..moveTo(cropRect.left + l, cropRect.bottom)
      ..lineTo(cropRect.left, cropRect.bottom)
      ..lineTo(cropRect.left, cropRect.bottom - l);

    canvas.drawPath(path, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CropMaskPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect;
  }
}
