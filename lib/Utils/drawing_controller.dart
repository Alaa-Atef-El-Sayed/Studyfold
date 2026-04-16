import 'dart:async';
import 'dart:io';
import 'dart:math' as Math;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:studyfold/Utils/drawing_controller_config.dart';
import 'package:studyfold/canvas_action.dart';
import 'package:studyfold/models/canvas_element.dart';
import 'package:studyfold/models/element_type.dart';
import 'package:studyfold/models/hive_shape.dart';
import 'package:studyfold/models/hive_stroke.dart';
import 'package:studyfold/models/movable_element.dart';
import 'package:studyfold/models/movable_element_data.dart';
import 'package:studyfold/models/shape_config.dart';
import 'package:studyfold/models/shape_type.dart';
import 'package:studyfold/models/stroke_type.dart';

enum CanvasMode { draw, edit }

enum CanvasDrawMode { brush, shape, eraser }

class DrawingController extends ChangeNotifier {
  DrawingControllerConfig config = DrawingControllerConfig();

  CanvasMode canvasMode = CanvasMode.draw;
  Timer? autoSaveTimer;
  final List<CanvasAction> actions = [];
  final List<CanvasAction> undoActions = [];
  final List<StrokeRecord> erasedBatch = [];
  final List<HiveShape> currentShapes = [];
  List<HiveStroke> strokes = [];
  List<CanvasElement> elements = [];
  Path? currentPath;
  Paint currentPaint = defaultPaint();
  double toolbarX = 0;
  double toolbarY = 0;
  double pageWidth = 794;
  double pageHeight = 1123;
  double currentScale = 1;

  ShapeConfig currentShapeConfig = const ShapeConfig();
  CanvasDrawMode currentDrawMode = CanvasDrawMode.brush;

  HiveStroke? lastStroke;

  // Might remove this later
  bool strokeAborted = false;

  bool capsuleToolbar = false;

  static Paint defaultPaint() => Paint()
    ..color = Colors.lightBlue
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 15.0
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true;

  Offset? previousPoint;
  bool isPanMode = false;
  List<Offset> currentPoints = [];

  Color selectedColor = Colors.white;
  double selectedSize = 15.0;

  List<MovableElement> images = [];
  List<MovableElement> documents = [];
  bool isDraggingElement = false;
  bool isDraggingShape = false;
  MovableElement? selectedElement;
  CanvasElement? selectedShape;
  bool isDrawing = false;
  bool isResizingMovableElement = false;
  bool isResizingShape = false;
  bool isDeletingMovableElement = false;
  bool isDeletingShape = false;
  bool isRotatingMovableElement = false;
  bool isRotatingShape = false;
  double initialRotation = 0.0;
  double initialTouchAngle = 0.0;
  Offset initialCenter = Offset.zero;
  Offset resizeAnchor = Offset.zero;
  ShapeType? currentShape = ShapeType.rectangle;
  Offset? shapeStartPoint;
  Offset? shapeEndPoint;

  Offset? _dragInitialTouch;
  Offset? _dragInitialStart;
  Offset? _dragInitialEnd;

  final GlobalKey linkMenuKey = GlobalKey();
  final GlobalKey shapeButtonKey = GlobalKey();
  final GlobalKey penButtonKey = GlobalKey();

  final GlobalKey toolbarKey = GlobalKey();
  late AnimationController dockController;
  late Animation<Offset> dockAnimation;

  Offset? eraserPoint;
  StrokeType strokeType = StrokeType.pen;

  TransformationController transformationController =
      TransformationController();

  double tempBorderWidth = 50;

  int pointersCount = 0;
  int previousPointersCount = 0;
  bool isTwoFingersDown = false;

  void centerViewport(Size layoutSize, Size canvasSize) {
    final double dx = (layoutSize.width - canvasSize.width) / 2;
    final double dy = (layoutSize.height - canvasSize.height) / 2;

    transformationController.value = Matrix4.identity()..translate(dx, dy);
  }

  void init() {
    dockController.addListener(() {
      toolbarX = dockAnimation.value.dx;
      toolbarY = dockAnimation.value.dy;
      notifyListeners();
    });

    images = elements
        .where(
          (element) =>
              element.movableElement != null &&
              element.movableElement!.type == ElementType.image,
        )
        .map((data) {
          return _createMovableElementFromData(data.movableElement!);
        })
        .toList();
  }

  @override
  void dispose() {
    transformationController.dispose();
    dockController.dispose();
    super.dispose();
  }

  void updateTwoFingerStatus() {
    isTwoFingersDown = pointersCount >= 2;
  }

  void updateCurrentPaint() {
    if (currentDrawMode == CanvasDrawMode.eraser) {
      // currentPaint = Paint()
      //   // ..blendMode = BlendMode.dstOut
      //   ..strokeCap = StrokeCap.round
      //   ..color = Colors.white
      //   ..strokeJoin = StrokeJoin.round
      //   ..strokeWidth = selectedSize * 2
      //   ..style = PaintingStyle.stroke
      //   ..isAntiAlias = true;
    } else {
      currentPaint = defaultPaint()
        ..color = selectedColor
        ..strokeWidth = selectedSize;
    }
  }

  Offset screenToCanvas(Offset screenPoint) {
    final matrix = transformationController.value;
    final inverseMatrix = Matrix4.inverted(matrix);
    return MatrixUtils.transformPoint(inverseMatrix, screenPoint);
  }

  Offset toLocal(Offset screenPoint) {
    final Matrix4 transformMatrix = transformationController.value;

    final Matrix4 inverseMatrix =
        Matrix4.tryInvert(transformMatrix) ?? Matrix4.identity();

    return MatrixUtils.transformPoint(inverseMatrix, screenPoint);
  }

  void addElement(CanvasElement element) {
    elements.add(element);
    notifyListeners();
  }

  void startDrawing(Offset position) {
    if (isPanMode || isTwoFingersDown) return;

    currentPoints = [position];

    if (currentDrawMode == CanvasDrawMode.eraser) {
      eraserPoint = position;
      eraseAt(position);
      notifyListeners();
      return;
    }

    updateCurrentPaint();
    Path newPath = Path();

    eraserPoint = position;
    currentPath = newPath;
    if (currentDrawMode == CanvasDrawMode.shape && previousPointersCount == 0) {
      if (shapeStartPoint != null) {
        shapeEndPoint = null;
        shapeStartPoint = null;
        notifyListeners();
        return;
      }
      shapeStartPoint = position;
    }
    notifyListeners();
  }

  void updateDrawing(Offset details) {
    // final currentPoint = details.localPosition;
    final currentPoint = screenToCanvas(details);
    if (currentPoints.isNotEmpty) {
      final lastPoint = currentPoints.last;
      // Only add the point if the finger moved more than 2 pixels
      if ((currentPoint - lastPoint).distance > 2.0) {
        currentPoints.add(currentPoint);
      }
    } else {
      currentPoints.add(currentPoint);
    }
    // currentPoints.add(currentPoint);
    eraserPoint = currentPoint;

    if (currentDrawMode == CanvasDrawMode.eraser) {
      eraseAt(currentPoint);
      notifyListeners();
    } else if (currentDrawMode == CanvasDrawMode.shape) {
      shapeEndPoint = currentPoint;
      notifyListeners();
    } else {
      // previousPoint ??= currentPoint;
      if (previousPoint == null && !strokeAborted) {
        strokes = List.from(
          strokes..add(
            HiveStroke(
              colorValue: selectedColor.toARGB32(),
              points: List.from(currentPoints),
              size: selectedSize,
              type: strokeType,
            ),
          ),
        );

        elements = elements
          ..add(
            CanvasElement(
              stroke: HiveStroke(
                colorValue: selectedColor.toARGB32(),
                points: List.from(currentPoints),
                size: selectedSize,
                type: strokeType,
              ),
            ),
          );

        previousPoint = currentPoint;
      }

      if (!strokeAborted) {
        previousPoint = currentPoint;
      }

      if (!strokeAborted) {
        // strokes.last = HiveStroke(
        //   colorValue: selectedColor.value,
        //   points: List.from(currentPoints),
        //   size: selectedSize,
        //   type: strokeType,
        // );

        lastStroke = HiveStroke(
          colorValue: selectedColor.toARGB32(),
          points: List.from(currentPoints),
          size: selectedSize,
          type: strokeType,
        );

        elements.last = CanvasElement(stroke: lastStroke);
      }
      notifyListeners();
    }
  }

  void eraseAt(Offset point) {
    final double eraserRadius = 40.0 / 2;

    final safeEraserRect = Rect.fromCenter(
      center: point,
      width: 40.0 + 100,
      height: 40.0 + 100,
    );

    final elementsToRemove = elements.where((element) {
      if (element.stroke == null) return false;
      final stroke = element.stroke!;
      if (!stroke.bounds.overlaps(safeEraserRect)) return false;
      return isEraserTouchingPath(stroke, point, eraserRadius);
    }).toList();

    if (elementsToRemove.isEmpty) return;

    for (final element in elementsToRemove) {
      final stroke = element.stroke!;
      int index = elements.indexOf(element);
      erasedBatch.add(StrokeRecord(stroke, index));
    }

    elements.removeWhere((s) => elementsToRemove.contains(s));
    notifyListeners();
  }

  bool isEraserTouchingPath(
    HiveStroke stroke,
    Offset eraserCenter,
    double eraserRadius,
  ) {
    final metrics = stroke.path.computeMetrics();

    final hitThreshold = eraserRadius + (stroke.paint.strokeWidth / 2);

    double totalPathLength = 0.0;

    for (final metric in metrics) {
      totalPathLength += metric.length;

      final double step = 5.0;
      for (double i = 0; i < metric.length; i += step) {
        final tangent = metric.getTangentForOffset(i);
        if (tangent == null) continue;

        final pathPoint = tangent.position;

        if ((pathPoint - eraserCenter).distance <= hitThreshold) {
          return true;
        }
      }
    }

    if (totalPathLength < 5.0) {
      final bounds = stroke.bounds;
      if ((bounds.center - eraserCenter).distance <= hitThreshold) {
        return true;
      }
    }

    return false;
  }

  void finishErasing() {
    if (erasedBatch.isNotEmpty) {
      actions.add(
        CanvasAction(
          type: ActionType.erase,
          strokes: List.from(erasedBatch),
          shapes: [],
        ),
      );
      erasedBatch.clear();
      undoActions.clear();
    }
  }

  void undo() {
    final lastAction = actions.removeLast();
    undoActions.add(lastAction);
    if (lastAction.type == ActionType.draw) {
      for (var record in lastAction.strokes) {
        // strokes.remove(record.stroke);
        elements.removeWhere((element) {
          return element.stroke != null &&
              element.stroke!.id == record.stroke.id;
        });
      }
    } else if (lastAction.type == ActionType.erase) {
      for (var record in lastAction.strokes) {
        if (record.index <= elements.length) {
          // strokes.insert(record.index, record.stroke);
          elements.insert(record.index, CanvasElement(stroke: record.stroke));
        } else {
          elements.add(CanvasElement(stroke: record.stroke));
          // strokes.add(record.stroke);
        }
      }
    } else if (lastAction.type == ActionType.addElement) {
      for (var record in lastAction.shapes) {
        elements.removeWhere((element) {
          if (element.shape != null &&
              selectedShape != null &&
              selectedShape!.shape!.id == element.shape!.id) {
            selectedShape = null;
          }
          return element.shape != null && element.shape!.id == record.shape.id;
        });
      }
    }
    notifyListeners();
  }

  void redo() {
    final action = undoActions.removeLast();
    actions.add(action);
    if (action.type == ActionType.draw) {
      for (var record in action.strokes) {
        // strokes.add(record.stroke);
        elements.add(CanvasElement(stroke: record.stroke));
      }
    } else if (action.type == ActionType.erase) {
      for (var record in action.strokes) {
        // strokes.remove(record.stroke);
        elements.removeWhere((element) {
          return element.stroke != null &&
              element.stroke!.id == record.stroke.id;
        });
      }
    } else if (action.type == ActionType.addElement) {
      for (var record in action.shapes) {
        elements.insert(record.index, CanvasElement(shape: record.shape));
      }
    }
    notifyListeners();
  }

  void abortStroke() {
    if (currentPath != null) {
      strokeAborted = true;
      // strokes.remove(lastStroke);
      elements.removeWhere(
        (element) => element.stroke != null && element.stroke == lastStroke,
      );
      currentPath = null;
      previousPoint = null;
    }
    notifyListeners();
  }

  void finishDrawing(Offset position) {
    finishErasing();

    eraserPoint = null;
    notifyListeners();

    if (previousPoint != null) {
      // final Path dotPath = drawDot(position);
      // currentPath!.lineTo(previousPoint!.dx, previousPoint!.dy);
      if (currentPath != null &&
          !strokeAborted &&
          currentDrawMode == CanvasDrawMode.brush) {
        lastStroke = elements.last.stroke!;
        actions.add(
          CanvasAction(
            type: ActionType.draw,
            strokes: [StrokeRecord(lastStroke!, elements.length - 1)],
            shapes: [],
          ),
        );
      }

      // strokes = List.from(
      //   strokes..add(
      //     HiveStroke(
      //       colorValue: selectedColor.value,
      //       points: List.from(currentPoints),
      //       size: selectedSize,
      //       type: strokeType
      //     ),
      //   ),
      // );

      undoActions.clear();
      notifyListeners();
    } else if (currentDrawMode == CanvasDrawMode.brush &&
        previousPointersCount == 1) {
      if (currentPath != null && !strokeAborted) {
        // strokes = strokes
        //   ..add(
        //     HiveStroke(
        //       colorValue: selectedColor.value,
        //       points: List.from(currentPoints),
        //       size: selectedSize,
        //       type: strokeType,
        //     ),
        //   );

        lastStroke = HiveStroke(
          colorValue: selectedColor.toARGB32(),
          points: List.from(currentPoints),
          size: selectedSize,
          type: strokeType,
        );

        elements = elements..add(CanvasElement(stroke: lastStroke));

        actions.add(
          CanvasAction(
            type: ActionType.draw,
            strokes: [StrokeRecord(lastStroke!, elements.length - 1)],
            shapes: [],
          ),
        );
      }

      undoActions.clear();
    } else if (currentDrawMode == CanvasDrawMode.shape &&
        previousPointersCount == 1) {
      if (shapeStartPoint == null || shapeEndPoint == null) return;
      final double dx = (shapeStartPoint! - shapeEndPoint!).dx;
      final double dy = (shapeStartPoint! - shapeEndPoint!).dy;
      if (dx.abs() < 50 || dy.abs() < 50) {
        shapeStartPoint = null;
        shapeEndPoint = null;
        return;
      }

      final Paint shapePaint = Paint()
        ..color = Colors.cyan
        ..style = PaintingStyle.fill;

      final shape = HiveShape(
        points: [],
        colorValue: selectedColor.value,
        size: selectedSize,
        type: currentShape!,
        shapeStartPoint: shapeStartPoint!,
        shapeEndPoint: shapeEndPoint!,
      );
      elements.add(CanvasElement(shape: shape));

      actions.add(
        CanvasAction(
          type: ActionType.addElement,
          strokes: [],
          shapes: [ShapeRecord(shape, currentShape!, elements.length - 1)],
          shapeStartPoint: shapeStartPoint,
          shapeEndPoint: shapeEndPoint,
          paint: shapePaint,
        ),
      );

      shapeStartPoint = null;
      shapeEndPoint = null;

      undoActions.clear();
    }
    currentPath = null;
    previousPoint = null;
    strokeAborted = false;
    lastStroke = null;
  }

  void handleDrawModeDown(Offset point) {
    selectedElement = null;

    if (pointersCount == 1) {
      isDrawing = true;
      startDrawing(point);
    } else {
      if (shapeStartPoint != null || shapeEndPoint != null) {
        shapeEndPoint = null;
        shapeStartPoint = null;
        notifyListeners();
        return;
      }
    }
  }

  void handleDrawModeMove(PointerMoveEvent event) {
    if (isDrawing) {
      updateDrawing(event.localPosition);
    }
  }

  void handleDrawModeUp(PointerUpEvent event) {
    if (isDrawing) {
      isDrawing = false;
      finishDrawing(event.localPosition);
    } else {
      if (shapeStartPoint != null || shapeEndPoint != null) {
        shapeEndPoint = null;
        shapeStartPoint = null;
        notifyListeners();
        return;
      }
    }
  }

  void handleEditModeDown(Offset point) {
    isDrawing = false;

    if (selectedElement != null) {
      if (selectedElement!.containsResize(point)) {
        isResizingMovableElement = true;

        initialCenter = Offset(
          selectedElement!.position.dx + selectedElement!.width / 2,
          selectedElement!.position.dy + selectedElement!.height / 2,
        );

        resizeAnchor = selectedElement!.getCorners();

        return;
      }
      if (selectedElement!.containsDelete(point)) {
        isDeletingMovableElement = true;
        return;
      }
      if (selectedElement!.containsRotate(point)) {
        isRotatingMovableElement = true;

        initialCenter = Offset(
          selectedElement!.position.dx + selectedElement!.width / 2,
          selectedElement!.position.dy + selectedElement!.height / 2,
        );

        initialTouchAngle = Math.atan2(
          point.dy - initialCenter.dy,
          point.dx - initialCenter.dx,
        );

        initialRotation = selectedElement!.rotation;

        return;
      }
    } else if (selectedShape != null) {
      if (selectedShape!.containsDelete(point, currentScale)) {
        isDeletingShape = true;
        return;
      } else if (selectedShape!.containsResize(point, currentScale)) {
        isResizingShape = true;
        return;
      } else if (selectedShape!.containsRotate(point, currentScale)) {
        isRotatingShape = true;

        initialCenter = Offset(
          selectedShape!.shape!.shapeStartPoint.dx +
              selectedShape!.shape!.shapeEndPoint.dx / 2,
          selectedShape!.shape!.shapeStartPoint.dy +
              selectedShape!.shape!.shapeEndPoint.dy / 2,
        );

        initialTouchAngle = Math.atan2(
          point.dy - initialCenter.dy,
          point.dx - initialCenter.dx,
        );

        initialRotation = selectedShape!.shape!.rotation;

        return;
      }
    }

    MovableElement? hitElement;
    CanvasElement? hitShape;
    for (CanvasElement element in elements.reversed) {
      if (element.shape != null && element.contains(point)) {
        hitShape = element;
        break;
      } else if (element.movableElement != null &&
          images
              .firstWhere((image) => image.id == element.movableElement!.id)
              .contains(point)) {
        hitElement = images.firstWhere(
          (image) => image.id == element.movableElement!.id,
        );
        break;
      }
      // if (element.contains(point)) {
      //   hitShape = element;
      //   break;
      // }
    }

    // for (var element in images.reversed) {
    //   if (hitShape != null) break;
    //   if (element.contains(point)) {
    //     hitElement = element;
    //     break;
    //   }
    // }

    for (var element in documents.reversed) {
      if (hitShape != null) break;
      if (element.contains(point)) {
        hitElement = element;
        break;
      }
    }

    if (hitElement != null) {
      selectedShape = null;
      isDraggingShape = false;
      selectedElement = hitElement;
      isDraggingElement = true;
    } else if (hitShape != null) {
      selectedElement = null;
      isDraggingElement = false;
      selectedShape = hitShape;
      isDraggingShape = true;

      _dragInitialTouch = point;
      _dragInitialStart = selectedShape!.shape!.shapeStartPoint;
      _dragInitialEnd = selectedShape!.shape!.shapeEndPoint;
    } else {
      selectedShape = null;
      selectedElement = null;
      isDraggingShape = false;
      isDraggingElement = false;
    }
  }

  void handleEditModeMove(PointerMoveEvent event) {
    if (selectedElement == null && selectedShape == null) return;

    if (isResizingMovableElement) {
      resizeElement(selectedElement!, event);
      return;
    }

    if (isRotatingMovableElement) {
      rotateElement(selectedElement!, event);
      return;
    }

    if (isResizingShape) {
      resizeShape(selectedShape!.shape!, event);
      return;
    }

    if (isRotatingShape) {
      rotateShape(selectedShape!.shape!, event);
      return;
    }

    if (isDraggingElement) {
      selectedElement!.position +=
          event.localDelta *
          (1 / transformationController.value.getMaxScaleOnAxis());
    }

    if (isDraggingShape) {
      final HiveShape shape = selectedShape!.shape!;
      if (shape.config.isLocked) return;
      if (!config.enableClamping) {
        shape.shapeStartPoint +=
            event.localDelta *
            (1 / transformationController.value.getMaxScaleOnAxis());

        shape.shapeEndPoint +=
            event.localDelta *
            (1 / transformationController.value.getMaxScaleOnAxis());
        notifyListeners();
        return;
      }
      final Offset currentTouch = toLocal(event.localPosition);
      final Offset totalDelta = (currentTouch - _dragInitialTouch!);

      final Offset desiredStart = _dragInitialStart! + totalDelta;
      final Offset desiredEnd = _dragInitialEnd! + totalDelta;

      double desiredLeft = math.min(desiredStart.dx, desiredEnd.dx);
      double desiredRight = math.max(desiredStart.dx, desiredEnd.dx);
      double desiredTop = math.min(desiredStart.dy, desiredEnd.dy);
      double desiredBottom = math.max(desiredStart.dy, desiredEnd.dy);

      final double width = desiredRight - desiredLeft;
      final double height = desiredBottom - desiredTop;

      final double desiredCenterX = desiredLeft + (width / 2);
      final double desiredCenterY = desiredTop + (height / 2);

      if ((desiredCenterX - config.clampCenterX).abs() < 15) {
        desiredLeft = config.clampCenterX - (width / 2);
        desiredRight = desiredLeft + width;
      }

      if ((desiredCenterY - config.clampCenterY).abs() < 15) {
        desiredTop = config.clampCenterY - (height / 2);
        desiredBottom = desiredTop + height;
      }

      if (desiredLeft < config.clampLowerLimitX) {
        desiredLeft = config.clampLowerLimitX;
        desiredRight = desiredLeft + width;
      } else if (desiredRight > config.clampUpperLimitX) {
        desiredRight = config.clampUpperLimitX;
        desiredLeft = desiredRight - width;
      }

      if (desiredTop < config.clampLowerLimitY) {
        desiredTop = config.clampLowerLimitY;
        desiredBottom = desiredTop + height;
      } else if (desiredBottom > config.clampUpperLimitY) {
        desiredBottom = config.clampUpperLimitY;
        desiredTop = desiredBottom - height;
      }

      final bool isStartLeft = _dragInitialStart!.dx < _dragInitialEnd!.dx;
      final bool isStartTop = _dragInitialStart!.dy < _dragInitialEnd!.dy;

      shape.shapeStartPoint = Offset(
        isStartLeft ? desiredLeft : desiredRight,
        isStartTop ? desiredTop : desiredBottom,
      );

      shape.shapeEndPoint = Offset(
        isStartLeft ? desiredRight : desiredLeft,
        isStartTop ? desiredBottom : desiredTop,
      );
    }
    notifyListeners();
  }

  void handleEditModeUp(PointerUpEvent event) {
    if (isDeletingMovableElement && selectedElement != null) {
      deleteElement(selectedElement!);
    } else if (isDeletingShape && selectedShape != null) {
      deleteShape(selectedShape!);
    }

    isResizingMovableElement = false;
    // isDeletingMovableElement = false;
    isDeletingShape = false;
    isResizingShape = false;
    isRotatingShape = false;
    isRotatingMovableElement = false;
    isDraggingElement = false;
    isDraggingShape = false;
    notifyListeners();
  }

  void deleteElement(MovableElement element) async {
    images.remove(element);
    elements.removeWhere(
      (thisElement) =>
          thisElement.movableElement != null &&
          thisElement.movableElement!.id == element.id,
    );
    selectedElement = null;
    notifyListeners();
    if (await File(element.filePath!).exists()) {
      await File(element.filePath!).delete();
    }
  }

  void deleteShape(CanvasElement shape) {
    elements.remove(shape);
    selectedShape = null;
    notifyListeners();
  }

  void resizeElement(MovableElement element, PointerMoveEvent event) {
    final Offset touchPoint = toLocal(event.localPosition);

    final double dx = touchPoint.dx - resizeAnchor.dx;
    final double dy = touchPoint.dy - resizeAnchor.dy;

    final double cosTheta = Math.cos(element.rotation);
    final double sinTheta = Math.sin(element.rotation);

    double newWidth = (dx * cosTheta) + (dy * sinTheta);

    if (newWidth < 50) newWidth = 50;
    if (newWidth > 500) newWidth = 500;

    element.width = newWidth;
    element.height = newWidth / element.aspectRatio!;

    final double centerX = newWidth / 2;
    final double centerY = element.height / 2;

    final double rotatedCenterX = centerX * cosTheta - centerY * sinTheta;
    final double rotatedCenterY = centerX * sinTheta + centerY * cosTheta;

    final Offset newCenter =
        resizeAnchor + Offset(rotatedCenterX, rotatedCenterY);

    element.position = Offset(
      newCenter.dx - newWidth / 2,
      newCenter.dy - element.height / 2,
    );
    notifyListeners();
  }

  void resizeShape(HiveShape shape, PointerMoveEvent event) {
    if (shape.config.isLocked) return;
    final Offset touchPoint = toLocal(event.localPosition);

    final double dx = touchPoint.dx - shape.shapeStartPoint.dx;
    final double dy = touchPoint.dy - shape.shapeStartPoint.dy;

    final double cosTheta = Math.cos(shape.rotation);
    final double sinTheta = Math.sin(shape.rotation);

    double newWidth = (dx * cosTheta) + (dy * sinTheta);

    if (dx > 50 && dy > 50) {
      shape.shapeEndPoint = touchPoint - Offset(20, 20);
    }
    notifyListeners();
  }

  void rotateElement(MovableElement element, PointerMoveEvent event) {
    final currentTouchAngle = Math.atan2(
      toLocal(event.localPosition).dy - initialCenter.dy,
      toLocal(event.localPosition).dx - initialCenter.dx,
    );

    final angleDelta = currentTouchAngle - initialTouchAngle;

    element.rotation = initialRotation + angleDelta;

    if (element.rotation.abs() * 180 / Math.pi < 5) {
      element.rotation = 0;
    }
    notifyListeners();
  }

  void rotateShape(HiveShape shape, PointerMoveEvent event) {
    if (shape.config.isLocked) return;
    final currentTouchAngle = Math.atan2(
      toLocal(event.localPosition).dy - initialCenter.dy,
      toLocal(event.localPosition).dx - initialCenter.dx,
    );

    final angleDelta = currentTouchAngle - initialTouchAngle;

    shape.rotation = initialRotation + angleDelta;

    if (shape.rotation.abs() * 180 / Math.pi < 5) {
      shape.rotation = 0;
    }
    notifyListeners();
  }

  Rect calculateViewport(Size screenSize) {
    final matrix = transformationController.value;
    final inverse = Matrix4.inverted(matrix);

    final topLeft = MatrixUtils.transformPoint(inverse, Offset.zero);
    final bottomRight = MatrixUtils.transformPoint(
      inverse,
      Offset(screenSize.width, screenSize.height),
    );

    return Rect.fromPoints(topLeft, bottomRight);
  }

  MovableElement _createMovableElementFromData(MovableElementData data) {
    late final Widget widget;

    if (data.type == ElementType.image) {
      widget = _buildImageWidget(
        data.filePath,
        data.id,
        data.width,
        data.height,
      );
    } else if (data.type == ElementType.document) {
      widget = _buildDocumentWidget(
        data.filePath,
        data.title ?? "Document",
        data.id,
        data.width,
        data.height,
      );
    }

    return MovableElement.fromData(data, widget);
  }

  Widget _buildDocumentWidget(
    String filePath,
    String name,
    String id,
    double width,
    double height,
  ) {
    return Container(
      constraints: BoxConstraints(maxWidth: 300),
      color: Colors.amber,
      child: Center(
        child: Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(
    String imagePath,
    String id,
    double width,
    double height,
  ) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.file(File(imagePath), fit: BoxFit.fill),
          ),
          // Positioned(
          //   top: 0,
          //   right: 0,
          //   child: IconButton(
          //     onPressed: () async {
          //       if (await File(imagePath).exists()) {
          //         await File(imagePath).delete();
          //       }
          //       setState(() {
          //         _images.removeWhere((element) => element.id == id);
          //       });
          //     },
          //     icon: const Icon(Icons.close, color: Colors.red, size: 26),
          //   ),
          // ),

          // // Bottom Right
          // Positioned(
          //   right: 0,
          //   bottom: 0,
          //   child: GestureDetector(
          //     onPanUpdate: (details) {
          //       final element = _images.firstWhere((e) => e.id == id);
          //       final newWidth = element.width + details.delta.dx;
          //       final newHeight = element.height + details.delta.dy;

          //       if (newWidth > 50 && newHeight > 50) {
          //         setState(() {
          //           element.width = newWidth;
          //           element.height = newHeight;
          //           element.widget = _buildImageWidget(
          //             imagePath,
          //             id,
          //             newWidth,
          //             newHeight,
          //           );
          //         });
          //       }
          //     },
          //     child: Container(
          //       width: 10,
          //       height: 10,
          //       decoration: BoxDecoration(
          //         color: Colors.white,
          //         shape: BoxShape.circle,
          //       ),
          //     ),
          //   ),
          // ),

          // // Bottom Left
          // Positioned(
          //   left: 0,
          //   bottom: 0,
          //   child: GestureDetector(
          //     onPanUpdate: (details) {
          //       final element = _images.firstWhere((e) => e.id == id);
          //       final newWidth = element.width - details.delta.dx;
          //       final newHeight = element.height + details.delta.dy;

          //       if (newWidth > 50 && newHeight > 50) {
          //         setState(() {
          //           element.width = newWidth;
          //           element.height = newHeight;
          //           element.position = Offset(
          //             element.position.dx + details.delta.dx,
          //             element.position.dy,
          //           );

          //           element.widget = _buildImageWidget(
          //             imagePath,
          //             id,
          //             newWidth,
          //             newHeight,
          //           );
          //         });
          //       }
          //     },
          //     child: Container(
          //       width: 10,
          //       height: 10,
          //       decoration: BoxDecoration(
          //         color: Colors.white,
          //         shape: BoxShape.circle,
          //       ),
          //     ),
          //   ),
          // ),

          // // Top Left
          // Positioned(
          //   left: 0,
          //   top: 0,
          //   child: GestureDetector(
          //     onPanUpdate: (details) {
          //       final element = _images.firstWhere((e) => e.id == id);
          //       final newWidth = element.width - details.delta.dx;
          //       final newHeight = element.height - details.delta.dy;

          //       if (newWidth > 50 && newHeight > 50) {
          //         setState(() {
          //           element.width = newWidth;
          //           element.height = newHeight;
          //           element.position = Offset(
          //             element.position.dx + details.delta.dx,
          //             element.position.dy + details.delta.dy,
          //           );

          //           element.widget = _buildImageWidget(
          //             imagePath,
          //             id,
          //             newWidth,
          //             newHeight,
          //           );
          //         });
          //       }
          //     },
          //     child: Container(
          //       width: 10,
          //       height: 10,
          //       decoration: BoxDecoration(
          //         color: Colors.white,
          //         shape: BoxShape.circle,
          //       ),
          //     ),
          //   ),
          // ),

          // // Top Right
          // Positioned(
          //   right: 0,
          //   top: 0,
          //   child: GestureDetector(
          //     onPanUpdate: (details) {
          //       final element = _images.firstWhere((e) => e.id == id);
          //       final newWidth = element.width + details.delta.dx;
          //       final newHeight = element.height - details.delta.dy;

          //       if (newWidth > 50 && newHeight > 50) {
          //         setState(() {
          //           element.width = newWidth;
          //           element.height = newHeight;
          //           element.position = Offset(
          //             element.position.dx,
          //             element.position.dy + details.delta.dy,
          //           );

          //           element.widget = _buildImageWidget(
          //             imagePath,
          //             id,
          //             newWidth,
          //             newHeight,
          //           );
          //         });
          //       }
          //     },
          //     child: Container(
          //       width: 10,
          //       height: 10,
          //       decoration: BoxDecoration(
          //         color: Colors.white,
          //         shape: BoxShape.circle,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
