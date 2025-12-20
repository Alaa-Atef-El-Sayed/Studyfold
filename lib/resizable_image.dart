import 'dart:io';

import 'package:flutter/material.dart';

class ResizableImage extends StatefulWidget {
  final String imagePath;
  final VoidCallback onDelete;
  final ValueChanged<Size> onResize;

  const ResizableImage({
    super.key,
    required this.imagePath,
    required this.onDelete,
    required this.onResize,
  });

  @override
  State<ResizableImage> createState() => _ResizableImageState();
}

class _ResizableImageState extends State<ResizableImage> {
  double width = 200;
  double height = 150;

  void _updateSize(double newWidth, double newHeight) {
    setState(() {
      width = newWidth;
      height = newHeight;
    });
    widget.onResize(Size(newWidth, newHeight));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(
              File(widget.imagePath),
              fit: BoxFit.fill,
              width: width,
              height: height,
            ),
          ),

          // Delete Button (top-right)
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: widget.onDelete,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),

          // Resize Handles (one at each corner)
          
          // Top-left corner
          Positioned(
            top: -5,
            left: -5,
            child: ResizeHandle(
              onDrag: (details) {
                final newWidth = width - details.delta.dx;
                final newHeight = height - details.delta.dy;
                if (newWidth > 50 && newHeight > 50) {
                  _updateSize(newWidth, newHeight);
                }
              },
            ),
          ),

          // Top-right corner
          Positioned(
            top: -5,
            right: -5,
            child: ResizeHandle(
              onDrag: (details) {
                final newWidth = width + details.delta.dx;
                final newHeight = height - details.delta.dy;
                if (newWidth > 50 && newHeight > 50) {
                  _updateSize(newWidth, newHeight);
                }
              },
            ),
          ),

          // Bottom-left corner
          Positioned(
            bottom: -5,
            left: -5,
            child: ResizeHandle(
              onDrag: (details) {
                final newWidth = width - details.delta.dx;
                final newHeight = height + details.delta.dy;
                if (newWidth > 50 && newHeight > 50) {
                  _updateSize(newWidth, newHeight);
                }
              },
            ),
          ),

          // Bottom-right corner
          Positioned(
            bottom: -5,
            right: -5,
            child: ResizeHandle(
              onDrag: (details) {
                final newWidth = width + details.delta.dx;
                final newHeight = height + details.delta.dy;
                if (newWidth > 50 && newHeight > 50) {
                  _updateSize(newWidth, newHeight);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// The resize handle widget (the circles at corners)
class ResizeHandle extends StatelessWidget {
  final Function(DragUpdateDetails) onDrag;

  const ResizeHandle({super.key, required this.onDrag});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: onDrag,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}