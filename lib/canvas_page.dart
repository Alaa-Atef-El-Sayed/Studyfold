import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:studyfold/canvas_action.dart';
import 'package:studyfold/models/canvas.dart' as CustomCanvas;
import 'package:studyfold/services/folder_service.dart';
import 'package:studyfold/stroke.dart';

import 'dart:ui' as ui;

class CanvasPage extends StatefulWidget {
  final String canvasId;
  final FolderService folderService;
  const CanvasPage({super.key, required this.canvasId, required this.folderService});

  @override
  State<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends State<CanvasPage> with WidgetsBindingObserver {
  Timer? _autoSaveTimer;
  final List<CanvasAction> _actions = [];
  final List<CanvasAction> _undoActions = [];
  final List<StrokeRecord> _erasedBatch = [];
  List<Stroke> _strokes = [];
  Path? _currentPath;
  Paint _currentPaint = _defaultPaint();
  double toolbarX = 0;
  double toolbarY = 300;
  double toolbarStartX = 0;
  double toolbarStartY = 0;
  bool toolbarActive = true;

  static Paint _defaultPaint() => Paint()
    ..color = Colors.lightBlue
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 15.0
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true;

  Offset? _previousPoint;
  bool _isEraserMode = false;
  bool _isPanMode = false;

  Color _selectedColor = Colors.red;
  double _selectedSize = 15.0;

  Offset? eraserPoint;

  TransformationController transformationController =
      TransformationController();

  void _updateCurrentPaint() {
    if (_isEraserMode) {
      // _currentPaint = Paint()
      //   // ..blendMode = BlendMode.dstOut
      //   ..strokeCap = StrokeCap.round
      //   ..color = Colors.white
      //   ..strokeJoin = StrokeJoin.round
      //   ..strokeWidth = _selectedSize * 2
      //   ..style = PaintingStyle.stroke
      //   ..isAntiAlias = true;
    } else {
      _currentPaint = _defaultPaint()
        ..color = _selectedColor
        ..strokeWidth = _selectedSize;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // _strokes = widget.folderService.getCanvasStrokes(widget.canvasId);
    // _initializeBackgroundCanvas();
    // transformationController.addListener(() {
    //   setState(() {});
    // });
  }

  @override
  void dispose() {
    transformationController.dispose();
    _saveCanvas();
    _autoSaveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveCanvas();
    }
  }

  Future<void> _saveCanvas() async {
    // todo
    // widget.folderService.updateCanvasStrokes(widget.canvasId, _strokes);
  }

  void _triggerAutoSave() {
    _autoSaveTimer?.cancel();

    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      _saveCanvas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Canvas'),
        actions: [
          Opacity(
            opacity: (_isPanMode) ? 0.5 : 1,
            child: IconButton(
              onPressed: () {
                setState(() {
                  _isPanMode = !_isPanMode;
                });
              },
              icon: const Icon(Icons.pan_tool),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _isEraserMode = !_isEraserMode;
              });
            },
            icon: Icon(_isEraserMode ? Icons.delete : Icons.brush),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(
                color: Colors.white,
                child: InteractiveViewer(
                  transformationController: transformationController,
                  panEnabled: _isPanMode,
                  scaleEnabled: _isPanMode,
                  minScale: 0.1,
                  maxScale: 5.0,
                  boundaryMargin: EdgeInsets.all(2000),
                  child: SizedBox(
                    width: 5000,
                    height: 5000,
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: transformationController,
                        builder: (context, child) {
                          final viewport = _calculateViewport(
                            constraints.biggest,
                          );
                          return CustomPaint(
                            painter: DrawingPainter(
                              _strokes,
                              viewport,
                              eraserPoint,
                              _isEraserMode,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // child: GestureDetector(
                  //   onPanStart: (details) {
                  //     if (_isPanMode) return;
                  //     _startDrawing(details.localPosition);
                  //   },
                  //   onPanUpdate: (details) {
                  //     if (_isPanMode) return;
                  //     final currentPoint = details.localPosition;

                  //     _previousPoint ??= currentPoint;

                  //     final midPoint = (_previousPoint! + currentPoint) / 2;

                  //     _currentPath!.quadraticBezierTo(
                  //       _previousPoint!.dx,
                  //       _previousPoint!.dy,
                  //       midPoint.dx,
                  //       midPoint.dy,
                  //     );
                  //     _previousPoint = currentPoint;

                  //     setState(() {
                  //       _strokes = List.from(_strokes);
                  //     });
                  //   },
                  //   onPanEnd: (details) {
                  //     if (_isPanMode) return;
                  //     if (_previousPoint != null) {
                  //       setState(() {
                  //         _currentPath!.lineTo(
                  //           _previousPoint!.dx,
                  //           _previousPoint!.dy,
                  //         );
                  //       });
                  //     }
                  //     _currentPath = null;
                  //     _previousPoint = null;
                  //   },

                  //   child: RepaintBoundary(
                  //     child: CustomPaint(painter: DrawingPainter(_strokes)),
                  //   ),
                  // ),
                ),
              ),

              if (!_isPanMode)
                GestureDetector(
                  onPanStart: (details) {
                    _startDrawing(details.localPosition);
                  },
                  onPanUpdate: (details) {
                    // final currentPoint = details.localPosition;
                    final currentPoint = _screenToCanvas(details.localPosition);
                    eraserPoint = currentPoint;
                    if (_isEraserMode) {
                      setState(() {
                        _eraseAt(currentPoint);
                      });
                    } else {
                      _previousPoint ??= currentPoint;

                      final midPoint = (_previousPoint! + currentPoint) / 2;

                      _currentPath!.quadraticBezierTo(
                        _previousPoint!.dx,
                        _previousPoint!.dy,
                        midPoint.dx,
                        midPoint.dy,
                      );
                      _previousPoint = currentPoint;

                      setState(() {
                        _strokes.last = Stroke(
                          color: _selectedColor,
                          size: _selectedSize,
                          paint: _currentPaint,
                          path: _currentPath!,
                        );
                      });
                    }
                  },
                  onPanEnd: (details) {
                    _finishErasing();
                    setState(() {
                      eraserPoint = null;
                    });
                    if (_previousPoint != null) {
                      setState(() {
                        _currentPath!.lineTo(
                          _previousPoint!.dx,
                          _previousPoint!.dy,
                        );
                        final newStroke = _strokes.last;

                        _actions.add(
                          CanvasAction(
                            type: ActionType.draw,
                            strokes: [
                              StrokeRecord(newStroke, _strokes.length - 1),
                            ],
                          ),
                        );

                        _undoActions.clear();
                      });
                    }
                    _currentPath = null;
                    _previousPoint = null;
                  },

                  child: Container(color: Colors.transparent),
                ),

              _buildToolBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolBar() {
    return Positioned(
      top: toolbarY,
      left: toolbarX,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.grey,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  toolbarX += details.delta.dx;
                  toolbarY += details.delta.dy;
                });
              },
              child: Container(width: 50, height: 50, color: Colors.amber),
            ),

            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: _actions.isNotEmpty
                  ? () {
                      setState(() {
                        final lastAction = _actions.removeLast();
                        _undoActions.add(lastAction);

                        if (lastAction.type == ActionType.draw) {
                          for (var record in lastAction.strokes) {
                            _strokes.remove(record.stroke);
                          }
                        } else if (lastAction.type == ActionType.erase) {
                          for (var record in lastAction.strokes) {
                            if (record.index <= _strokes.length) {
                              _strokes.insert(record.index, record.stroke);
                            } else {
                              _strokes.add(record.stroke);
                            }
                          }
                        }
                      });
                    }
                  : null,
            ),

            IconButton(
              icon: const Icon(Icons.redo),
              onPressed: _undoActions.isNotEmpty
                  ? () {
                      setState(() {
                        final action = _undoActions.removeLast();
                        _actions.add(action);

                        if (action.type == ActionType.draw) {
                          for (var record in action.strokes) {
                            _strokes.add(record.stroke);
                          }
                        } else if (action.type == ActionType.erase) {
                          for (var record in action.strokes) {
                            _strokes.remove(record.stroke);
                          }
                        }
                      });
                    }
                  : null,
            ),

            SizedBox(
              height: 50,
              child: Slider(
                activeColor: const Color.fromARGB(255, 7, 205, 255),
                // label: "Brush Size",
                value: _selectedSize,
                min: 1.0,
                max: 100.0,
                onChanged: (value) {
                  setState(() {
                    _selectedSize = value;
                  });
                },
              ),
            ),

            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Pick a Color"),
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: _selectedColor,
                        onColorChanged: (color) {
                          setState(() {
                            _isEraserMode = false;
                            _selectedColor = color;
                          });
                        },
                      ),
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("Done"),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.color_lens),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorIcon(Color color) {
    return IconButton(
      icon: Icon(Icons.circle, color: color),
      onPressed: () {
        setState(() {
          _isEraserMode = false;
          _selectedColor = color;
        });
      },
    );
  }

  Path _drawDot(Offset position) {
    final dotPath = Path();
    dotPath.moveTo(position.dx, position.dy);
    dotPath.lineTo(position.dx, position.dy);
    // final dotStroke = Stroke(
    //   color: _selectedColor,
    //   paint: _currentPaint,
    //   path: dotPath,
    //   size: _selectedSize,
    // );
    // setState(() {
    //   // _paths = List.from(_paths)..add(dotPath);
    //   _strokes = List.from(_strokes)..add(dotStroke);
    // });
    return dotPath;
  }

  void _startDrawing(Offset position) {
    position = _screenToCanvas(position);
    if (_isEraserMode) {
      setState(() {
        eraserPoint = position;
      });
      return;
    }
    _updateCurrentPaint();
    Path dotPath = _drawDot(position);
    setState(() {
      eraserPoint = position;
      _currentPath = dotPath;
      _currentPath!.moveTo(position.dx, position.dy);
      _previousPoint = position;

      // _strokes.last = Stroke(
      //   color: _selectedColor,
      //   size: _selectedSize,
      //   paint: _currentPaint,
      //   path: _currentPath!,
      // );

      _strokes = List.from(
        // _strokes
        _strokes..add(
          Stroke(
            color: _selectedColor,
            size: _selectedSize,
            paint: _currentPaint,
            path: _currentPath!,
          ),
          // ),
        ),
      );
    });
  }

  Offset _screenToCanvas(Offset screenPoint) {
    final matrix = transformationController.value;
    final inverseMatrix = Matrix4.inverted(matrix);
    return MatrixUtils.transformPoint(inverseMatrix, screenPoint);
  }

  Rect _calculateViewport(Size screenSize) {
    final matrix = transformationController.value;
    final inverse = Matrix4.inverted(matrix);

    final topLeft = MatrixUtils.transformPoint(inverse, Offset.zero);
    final bottomRight = MatrixUtils.transformPoint(
      inverse,
      Offset(screenSize.width, screenSize.height),
    );

    return Rect.fromPoints(topLeft, bottomRight);
  }

  bool _isEraserTouchingPath(
    Stroke stroke,
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

  void _eraseAt(Offset point) {
    final double eraserRadius = 40.0 / 2;

    final safeEraserRect = Rect.fromCenter(
      center: point,
      width: 40.0 + 100,
      height: 40.0 + 100,
    );

    final strokesToRemove = _strokes.where((stroke) {
      if (!stroke.bounds.overlaps(safeEraserRect)) return false;
      return _isEraserTouchingPath(stroke, point, eraserRadius);
    }).toList();

    if (strokesToRemove.isEmpty) return;

    setState(() {
      for (final stroke in strokesToRemove) {
        int index = _strokes.indexOf(stroke);
        _erasedBatch.add(StrokeRecord(stroke, index));
      }

      _strokes.removeWhere((s) => strokesToRemove.contains(s));
    });
  }

  void _finishErasing() {
    if (_erasedBatch.isNotEmpty) {
      _actions.add(
        CanvasAction(type: ActionType.erase, strokes: List.from(_erasedBatch)),
      );
      _erasedBatch.clear();
      _undoActions.clear();
    }
  }
}

class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Rect viewport;
  final Offset? eraserPoint;
  final bool isEraserMode;

  DrawingPainter(
    this.strokes,
    this.viewport,
    this.eraserPoint,
    this.isEraserMode,
  );

  static final Paint _eraserFillPaint = Paint()
    ..color = Colors.black.withOpacity(0.1)
    ..style = PaintingStyle.fill;

  // 2. Thin border for visibility on dark backgrounds
  static final Paint _eraserBorderPaint = Paint()
    ..color = Colors.black.withOpacity(0.3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  static final eraserSize = 40.0;

  @override
  void paint(Canvas canvas, Size size) {
    for (Stroke stroke in strokes) {
      if (viewport.overlaps(stroke.bounds)) {
        canvas.drawPath(stroke.path, stroke.paint);
        // canvas.drawRect(
        //   stroke.bounds,
        //   Paint()
        //     ..style = PaintingStyle.stroke
        //     ..color = Colors.red,
        // );
      }
    }

    if (isEraserMode && eraserPoint != null) {
      canvas.drawCircle(eraserPoint!, eraserSize / 2, _eraserFillPaint);
      canvas.drawCircle(eraserPoint!, eraserSize / 2, _eraserBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    // return oldDelegate.strokes != strokes;
    return true;
  }
}
