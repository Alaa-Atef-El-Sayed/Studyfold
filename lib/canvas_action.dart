import 'package:studyfold/stroke.dart';

enum ActionType { draw, erase }

class StrokeRecord {
  final Stroke stroke;
  final int index;

  StrokeRecord(this.stroke, this.index);
}

class CanvasAction {
  final ActionType type;
  final List<StrokeRecord> strokes; 

  CanvasAction({
    required this.type,
    required this.strokes,
  });
}