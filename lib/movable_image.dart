import 'package:flutter/material.dart';

class MovableImage extends StatefulWidget {
  @override
  _MovableImageState createState() => _MovableImageState();
}

class _MovableImageState extends State<MovableImage> {
  Offset _position = Offset.zero;
  Matrix4 _transform = Matrix4.identity();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        _transform = Matrix4.identity()
          ..translate(details.localPosition.dx, details.localPosition.dy);
        setState(() {});
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 100),
        transform: _transform,
        child: Container(),
      ),
    );
  }
}