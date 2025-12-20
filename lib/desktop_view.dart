import 'package:flutter/material.dart';
import 'package:studyfold/grid_painter.dart';
import 'package:studyfold/models/note.dart';

class DesktopView extends StatefulWidget {
  final List<Note> notes;

  const DesktopView({super.key, required this.notes});

  @override
  _DesktopViewState createState() => _DesktopViewState();
}

class _DesktopViewState extends State<DesktopView> {
  final TransformationController _transformationController =
      TransformationController();
  static const double desktopWidth = 2000;
  static const double desktopHeight = 2000;
  Offset _startOffset = Offset.zero;
  Offset _startGlobalOffset = Offset.zero;
  Offset _offset = Offset.zero;
  bool isPanning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Desktop View')),
      body: InteractiveViewer(
        transformationController: _transformationController,
        boundaryMargin: EdgeInsets.zero,
        minScale: 0.1,
        maxScale: 5.0,
        constrained: false,
        child: Container(
          width: desktopWidth,
          height: desktopHeight,
          color: Colors.grey,
          child: Stack(
            children: [
              _buildGrid(),
              ...widget.notes.map((item) => _buildDesktopItem(item)),
              // Positioned(
              //   left: _offset.dx,
              //   top: _offset.dy,
              //   child: GestureDetector(
              //     onLongPressStart: (details) {
              //       _startOffset = _offset;
              //       _startGlobalOffset = details.globalPosition;
              //       setState(() {});
              //     },
              //     onLongPressMoveUpdate: (details) {
              //       final Offset totalDelta =
              //           details.globalPosition - _startGlobalOffset;
              //       setState(() {
              //         final finalOffset = _startOffset + totalDelta;
              //         _offset = Offset(
              //           finalOffset.dx.clamp(0, 500),
              //           finalOffset.dy.clamp(0, 500),
              //         );
              //       });
              //     },
              //     onTap: () => print('Container tapped'),
              //     child: Container(
              //       width: 200,
              //       height: 200,
              //       color: Colors.red,
              //       child: Center(child: Text('200x200')),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopItem(Note item) {
    return Positioned(
      left: item.positionX,
      top: item.positionY,
      child: GestureDetector(
        onLongPressStart: (details) {
          _startOffset = Offset(item.positionX, item.positionY);
          _startGlobalOffset = details.globalPosition;
          // setState(() {});
        },
        onLongPressMoveUpdate: (details) {
          final Offset totalDelta = details.globalPosition - _startGlobalOffset;
          setState(() {
          final finalOffset = _startOffset + totalDelta;
          item.positionX = finalOffset.dx.clamp(0, 500);
          item.positionY = finalOffset.dy.clamp(0, 500);
          });
        },
        onLongPressEnd: (details) {
          setState(() {});
        },
        onTap: () {},
        child: Container(
          width: 50,
          height: 50,
          color: Colors.red,
          child: const Icon(Icons.edit_document),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return CustomPaint(
      painter: GridPainter(),
      size: Size(desktopWidth, desktopHeight),
    );
  }

  // Widget _buildDesktopItem(DesktopItem item) {
  //   return Positioned(
  //     left: item.position.dx,
  //     top: item.position.dy,
  //     child: DraggableDesktopItem(
  //       item: item,
  //       onPositionChanged: (newPosition) {
  //         setState(() {
  //           item.position = newPosition;
  //         });
  //       },
  //     ),
  //   );
  // }
}
