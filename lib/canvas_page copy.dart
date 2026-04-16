// import 'dart:async';
// import 'dart:io';
// import 'dart:math' as Math;
// import 'dart:typed_data';
// import 'dart:ui';
// import 'dart:ui' as ui;

// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_colorpicker/flutter_colorpicker.dart';
// import 'package:flutter_portal/flutter_portal.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path/path.dart' as p;
// import 'package:path_provider/path_provider.dart';
// import 'package:studyfold/Icons/my_custom_icons.dart';
// import 'package:studyfold/canvas_action.dart';
// import 'package:studyfold/overlays/border_settings_popup.dart';
// import 'package:studyfold/overlays/link_menu_popup.dart';
// import 'package:studyfold/models/canvas_element.dart';
// import 'package:studyfold/models/element_type.dart';
// import 'package:studyfold/models/hive_shape.dart';
// import 'package:studyfold/models/hive_stroke.dart';
// import 'package:studyfold/models/movable_element.dart';
// import 'package:studyfold/models/movable_element_data.dart';
// import 'package:studyfold/models/shape_type.dart';
// import 'package:studyfold/models/stroke_type.dart';
// import 'package:studyfold/models/canvas.dart' as hive_canvas;
// import 'package:studyfold/overlays/pen_settings_button.dart';
// import 'package:studyfold/models/shape_config.dart';
// import 'package:studyfold/services/folder_service.dart';
// import 'package:studyfold/overlays/shape_menu_popup.dart';
// import 'package:studyfold/stroke.dart';
// import 'package:studyfold/widgets/color_circle.dart';

// enum CanvasMode { draw, edit }

// enum CanvasDrawMode { brush, shape, eraser }

// class CanvasPage extends StatefulWidget {
//   final String canvasId;
//   final FolderService folderService;
//   const CanvasPage({
//     super.key,
//     required this.canvasId,
//     required this.folderService,
//   });

//   @override
//   State<CanvasPage> createState() => _CanvasPageState();
// }

// class _CanvasPageState extends State<CanvasPage>
//     with WidgetsBindingObserver, TickerProviderStateMixin {
//   CanvasMode _canvasMode = CanvasMode.draw;
//   Timer? _autoSaveTimer;
//   final List<CanvasAction> _actions = [];
//   final List<CanvasAction> _undoActions = [];
//   final List<StrokeRecord> _erasedBatch = [];
//   final List<HiveShape> _currentShapes = [];
//   List<HiveStroke> _strokes = [];
//   List<CanvasElement> _elements = [];
//   Path? _currentPath;
//   Paint _currentPaint = _defaultPaint();
//   double toolbarX = 0;
//   double toolbarY = 0;
//   double pageWidth = 794;
//   double pageHeight = 1123;
//   double currentScale = 1;

//   ShapeConfig _currentShapeConfig = const ShapeConfig();
//   CanvasDrawMode _currentDrawMode = CanvasDrawMode.brush;

//   HiveStroke? lastStroke;

//   // Might remove this later
//   bool _strokeAborted = false;

//   bool capsuleToolbar = false;

//   static Paint _defaultPaint() => Paint()
//     ..color = Colors.lightBlue
//     ..strokeCap = StrokeCap.round
//     ..strokeWidth = 15.0
//     ..strokeJoin = StrokeJoin.round
//     ..style = PaintingStyle.stroke
//     ..isAntiAlias = true;

//   Offset? _previousPoint;
//   bool _isPanMode = false;
//   List<Offset> _currentPoints = [];

//   Color _selectedColor = Colors.white;
//   double _selectedSize = 15.0;

//   List<MovableElement> _images = [];
//   List<MovableElement> _documents = [];
//   bool _isDraggingElement = false;
//   bool _isDraggingShape = false;
//   MovableElement? _selectedElement;
//   CanvasElement? _selectedShape;
//   bool _isDrawing = false;
//   bool _isResizingMovableElement = false;
//   bool _isResizingShape = false;
//   bool _isDeletingMovableElement = false;
//   bool _isDeletingShape = false;
//   bool _isRotatingMovableElement = false;
//   bool _isRotatingShape = false;
//   double _initialRotation = 0.0;
//   double _initialTouchAngle = 0.0;
//   Offset _initialCenter = Offset.zero;
//   Offset _resizeAnchor = Offset.zero;
//   ShapeType? _currentShape = ShapeType.rectangle;
//   Offset? _shapeStartPoint;
//   Offset? _shapeEndPoint;

//   final GlobalKey _linkMenuKey = GlobalKey();
//   final GlobalKey _shapeButtonKey = GlobalKey();
//   final GlobalKey _penButtonKey = GlobalKey();

//   final GlobalKey _toolbarKey = GlobalKey();
//   late AnimationController _dockController;
//   late Animation<Offset> _dockAnimation;

//   Offset? eraserPoint;
//   StrokeType _strokeType = StrokeType.pen;

//   TransformationController transformationController =
//       TransformationController();

//   void _updateCurrentPaint() {
//     if (_currentDrawMode == CanvasDrawMode.eraser) {
//       // _currentPaint = Paint()
//       //   // ..blendMode = BlendMode.dstOut
//       //   ..strokeCap = StrokeCap.round
//       //   ..color = Colors.white
//       //   ..strokeJoin = StrokeJoin.round
//       //   ..strokeWidth = _selectedSize * 2
//       //   ..style = PaintingStyle.stroke
//       //   ..isAntiAlias = true;
//     } else {
//       _currentPaint = _defaultPaint()
//         ..color = _selectedColor
//         ..strokeWidth = _selectedSize;
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _dockController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );

//     _dockController.addListener(() {
//       setState(() {
//         toolbarX = _dockAnimation.value.dx;
//         toolbarY = _dockAnimation.value.dy;
//       });
//     });
//     WidgetsBinding.instance.addObserver(this);
//     hive_canvas.Canvas canvas =
//         widget.folderService.getItemById(widget.canvasId)['file']
//             as hive_canvas.Canvas;

//     _elements = widget.folderService.getCanvasElements(widget.canvasId);

//     _images = _elements
//         .where(
//           (element) =>
//               element.movableElement != null &&
//               element.movableElement!.type == ElementType.image,
//         )
//         .map((data) {
//           return _createMovableElementFromData(data.movableElement!);
//         })
//         .toList();

//     _documents = canvas.documents.map((data) {
//       return _createMovableElementFromData(data);
//     }).toList();
//     // _initializeBackgroundCanvas();
//     // transformationController.addListener(() {
//     //   setState(() {});
//     // });
//   }

//   @override
//   void dispose() {
//     transformationController.dispose();
//     _dockController.dispose();
//     _saveCanvas();
//     _autoSaveTimer?.cancel();
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.paused ||
//         state == AppLifecycleState.detached ||
//         state == AppLifecycleState.inactive) {
//       _saveCanvas();
//     }
//   }

//   Future<void> _saveCanvas() async {
//     // todo
//     widget.folderService.updateCanvasStrokes(widget.canvasId, _strokes);
//     widget.folderService.updateCanvasElements(widget.canvasId, _elements);

//     final imagesData = _images.map((element) {
//       return element.toData();
//     }).toList();

//     final documentsData = _documents.map((element) {
//       return element.toData();
//     }).toList();

//     widget.folderService.updateCanvasImages(widget.canvasId, imagesData);
//     widget.folderService.updateCanvasDocuments(widget.canvasId, documentsData);
//   }

//   void _triggerAutoSave() {
//     _autoSaveTimer?.cancel();

//     _autoSaveTimer = Timer(const Duration(seconds: 2), () {
//       _saveCanvas();
//     });
//   }

//   double _tempBorderWidth = 50;

//   int _pointersCount = 0;
//   int _previousPointersCount = 0;
//   bool _isTwoFingersDown = false;
//   void _updateTwoFingerStatus() {
//     _isTwoFingersDown = _pointersCount >= 2;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenSize = MediaQuery.of(context).size;
//     final padding = MediaQuery.of(context).padding;

//     final Size toolbarSize = getSize();
//     final double toolbarHeight = toolbarSize.height;
//     final double toolbarWidth = toolbarSize.width;

//     toolbarX = toolbarX.clamp(0, screenSize.width - toolbarWidth);
//     toolbarY = toolbarY.clamp(
//       0,
//       screenSize.height - toolbarHeight - kToolbarHeight - padding.top,
//     );

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Canvas'),
//         actions: [
//           Opacity(
//             opacity: (_isPanMode) ? 0.5 : 1,
//             child: IconButton(
//               onPressed: () {
//                 setState(() {
//                   _isPanMode = !_isPanMode;
//                 });
//               },
//               icon: const Icon(Icons.pan_tool),
//             ),
//           ),
//         ],
//       ),
//       body: Portal(
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             final viewport = _calculateViewport(constraints.biggest);
//             return Stack(
//               children: [
//                 Listener(
//                   onPointerDown: (event) {
//                     setState(() {
//                       _previousPointersCount = _pointersCount++;
//                       _updateTwoFingerStatus();

//                       if ((_isPanMode || _isTwoFingersDown)) {
//                         _abortStroke();
//                         return;
//                       }

//                       final point = _toLocal(event.localPosition);

//                       if (_canvasMode == CanvasMode.edit) {
//                         _handleEditModeDown(point);
//                       } else {
//                         _handleDrawModeDown(point);
//                       }
//                     });
//                   },

//                   onPointerMove: (event) {
//                     if (_isPanMode || _isTwoFingersDown) return;

//                     if (_canvasMode == CanvasMode.edit) {
//                       _handleEditModeMove(event);
//                     } else {
//                       _handleDrawModeMove(event);
//                     }
//                   },

//                   onPointerUp: (event) {
//                     setState(() {
//                       _previousPointersCount = _pointersCount--;
//                       _updateTwoFingerStatus();

//                       if (_canvasMode == CanvasMode.edit) {
//                         _handleEditModeUp(event);
//                       } else {
//                         _handleDrawModeUp(event);
//                       }
//                     });
//                   },
//                   onPointerCancel: (event) {
//                     setState(() {
//                       _previousPointersCount = _pointersCount;
//                       _pointersCount = 0;
//                       _updateTwoFingerStatus();
//                       if (_isPanMode || _isTwoFingersDown) return;
//                       _isDrawing = false;
//                       _finishDrawing(event.localPosition);
//                     });
//                   },
//                   child: InteractiveViewer(
//                     transformationController: transformationController,
//                     panEnabled: _isPanMode || _isTwoFingersDown,
//                     scaleEnabled: true,
//                     minScale: 0.1,
//                     maxScale: 3.0,
//                     onInteractionEnd: (details) {
//                       setState(() {
//                         currentScale = transformationController.value
//                             .getMaxScaleOnAxis();
//                       });
//                     },
//                     boundaryMargin: EdgeInsets.all(1000),
//                     child: Stack(
//                       children: [
//                         SizedBox(
//                           width: double.infinity,
//                           height: double.infinity,
//                           child: CustomPaint(
//                             painter: BackgroundPainter(1000, 1000, viewport),
//                           ),
//                         ),
//                         SizedBox(
//                           width: double.infinity,
//                           height: double.infinity,
//                           child: RepaintBoundary(
//                             child: AnimatedBuilder(
//                               animation: transformationController,
//                               builder: (context, child) {
//                                 return CustomPaint(
//                                   painter: DrawingPainter(
//                                     _actions,
//                                     viewport,
//                                     eraserPoint,
//                                     _currentDrawMode == CanvasDrawMode.eraser,
//                                     _shapeStartPoint,
//                                     _shapeEndPoint,
//                                     _currentShape,
//                                     _selectedColor,
//                                     _elements,
//                                     _selectedShape,
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                         ),

//                         SizedBox(
//                           width: double.infinity,
//                           height: double.infinity,
//                           child: Stack(
//                             clipBehavior: Clip.none,
//                             children: [
//                               ..._documents.map((element) {
//                                 final isSelected = _selectedElement == element;
//                                 final showControls =
//                                     isSelected && !_isDraggingElement;

//                                 return Positioned(
//                                   left: element.position.dx,
//                                   top: element.position.dy,
//                                   child: Transform.rotate(
//                                     angle: element.rotation,
//                                     alignment: Alignment.center,
//                                     child: Stack(
//                                       clipBehavior: Clip.none,
//                                       children: [
//                                         Container(
//                                           width: element.width,
//                                           height: element.height,
//                                           decoration: BoxDecoration(
//                                             border: Border.all(
//                                               color: isSelected
//                                                   ? Colors.blueAccent
//                                                   : Colors.transparent,
//                                               width: 2,
//                                             ),
//                                           ),
//                                           child: element.widget,
//                                         ),

//                                         Positioned(
//                                           top: -15,
//                                           right: -15,
//                                           child: AnimatedOpacity(
//                                             duration: const Duration(
//                                               milliseconds: 200,
//                                             ),
//                                             opacity: showControls ? 1.0 : 0.0,
//                                             child: Container(
//                                               width: 40,
//                                               height: 40,
//                                               padding: const EdgeInsets.all(4),
//                                               decoration: const BoxDecoration(
//                                                 color: Colors.red,
//                                                 shape: BoxShape.circle,
//                                                 boxShadow: [
//                                                   BoxShadow(
//                                                     blurRadius: 4,
//                                                     color: Colors.black26,
//                                                   ),
//                                                 ],
//                                               ),
//                                               child: const Icon(
//                                                 Icons.close,
//                                                 size: 18,
//                                                 color: Colors.white,
//                                               ),
//                                             ),
//                                           ),
//                                         ),

//                                         Positioned(
//                                           bottom: -15,
//                                           right: -15,
//                                           child: AnimatedOpacity(
//                                             duration: const Duration(
//                                               milliseconds: 200,
//                                             ),
//                                             opacity: showControls ? 1.0 : 0.0,
//                                             child: Container(
//                                               width: 40,
//                                               height: 40,
//                                               decoration: BoxDecoration(
//                                                 color: Colors.white,
//                                                 shape: BoxShape.circle,
//                                                 border: Border.all(
//                                                   color: Colors.blueAccent,
//                                                   width: 2,
//                                                 ),
//                                                 boxShadow: const [
//                                                   BoxShadow(
//                                                     blurRadius: 4,
//                                                     color: Colors.black26,
//                                                   ),
//                                                 ],
//                                               ),
//                                               child: const Icon(
//                                                 Icons.open_in_full,
//                                                 size: 18,
//                                                 color: Colors.blueAccent,
//                                               ),
//                                             ),
//                                           ),
//                                         ),

//                                         Positioned(
//                                           bottom: -15,
//                                           left: -15,
//                                           child: AnimatedOpacity(
//                                             duration: const Duration(
//                                               milliseconds: 200,
//                                             ),
//                                             opacity: showControls ? 1.0 : 0.0,
//                                             child: Container(
//                                               width: 40,
//                                               height: 40,
//                                               decoration: BoxDecoration(
//                                                 color: Colors.white,
//                                                 shape: BoxShape.circle,
//                                                 border: Border.all(
//                                                   color: Colors.blueAccent,
//                                                   width: 2,
//                                                 ),
//                                                 boxShadow: const [
//                                                   BoxShadow(
//                                                     blurRadius: 4,
//                                                     color: Colors.black26,
//                                                   ),
//                                                 ],
//                                               ),
//                                               child: const Icon(
//                                                 Icons.rotate_left,
//                                                 size: 18,
//                                                 color: Colors.blueAccent,
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 );
//                               }),

//                               ..._buildCanvasLayers(viewport),

//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),

//                 Positioned(
//                   bottom: 0,
//                   child: AnimatedSwitcher(
//                     duration: const Duration(milliseconds: 100),
//                     transitionBuilder: (child, animation) {
//                       return SlideTransition(
//                         position: Tween<Offset>(
//                           begin: Offset(0.0, 1.0),
//                           end: Offset(0, 0),
//                         ).animate(animation),
//                         child: child,
//                       );
//                     },
//                     child: (_selectedShape == null)
//                         ? SizedBox.shrink()
//                         : Container(
//                             key: ValueKey(
//                               _selectedShape == null &&
//                                   _selectedElement == null,
//                             ),
//                             color: Colors.transparent,
//                             width: screenSize.width,
//                             child: _buildElementOptions(),
//                           ),
//                   ),
//                 ),

//                 // InteractiveViewer(
//                 //   transformationController: transformationController,
//                 //   panEnabled: _isPanMode,
//                 //   scaleEnabled: _isPanMode,
//                 //   minScale: 0.1,
//                 //   maxScale: 3.0,
//                 //   boundaryMargin: EdgeInsets.all(1000),
//                 //   child: Stack(
//                 //     children: [
//                 //       SizedBox(
//                 //         width: double.infinity,
//                 //         height: double.infinity,
//                 //         child: CustomPaint(
//                 //           painter: BackgroundPainter(1000, 1000),
//                 //         ),
//                 //       ),
//                 //       SizedBox(
//                 //         width: double.infinity,
//                 //         height: double.infinity,
//                 //         child: RepaintBoundary(
//                 //           child: AnimatedBuilder(
//                 //             animation: transformationController,
//                 //             builder: (context, child) {
//                 //               final viewport = _calculateViewport(
//                 //                 constraints.biggest,
//                 //               );
//                 //               return CustomPaint(
//                 //                 painter: DrawingPainter(
//                 //                   _strokes,
//                 //                   viewport,
//                 //                   eraserPoint,
//                 //                   _isEraserMode,
//                 //                 ),
//                 //               );
//                 //             },
//                 //           ),
//                 //         ),
//                 //       ),
//                 //     ],
//                 //   ),
//                 // ),

//                 // child: GestureDetector(
//                 //   onPanStart: (details) {
//                 //     if (_isPanMode) return;
//                 //     _startDrawing(details.localPosition);
//                 //   },
//                 //   onPanUpdate: (details) {
//                 //     if (_isPanMode) return;
//                 //     final currentPoint = details.localPosition;

//                 //     _previousPoint ??= currentPoint;

//                 //     final midPoint = (_previousPoint! + currentPoint) / 2;

//                 //     _currentPath!.quadraticBezierTo(
//                 //       _previousPoint!.dx,
//                 //       _previousPoint!.dy,
//                 //       midPoint.dx,
//                 //       midPoint.dy,
//                 //     );
//                 //     _previousPoint = currentPoint;

//                 //     setState(() {
//                 //       _strokes = List.from(_strokes);
//                 //     });
//                 //   },
//                 //   onPanEnd: (details) {
//                 //     if (_isPanMode) return;
//                 //     if (_previousPoint != null) {
//                 //       setState(() {
//                 //         _currentPath!.lineTo(
//                 //           _previousPoint!.dx,
//                 //           _previousPoint!.dy,
//                 //         );
//                 //       });
//                 //     }
//                 //     _currentPath = null;
//                 //     _previousPoint = null;
//                 //   },

//                 //   child: RepaintBoundary(
//                 //     child: CustomPaint(painter: DrawingPainter(_strokes)),
//                 //   ),
//                 // ),
//                 // GestureDetector(
//                 //   behavior: HitTestBehavior.opaque,
//                 //   onPanStart: (details) {
//                 //     _startDrawing(details.localPosition);
//                 //   },
//                 //   onPanUpdate: (details) {
//                 //     _updateDrawing(details);
//                 //   },
//                 //   onPanEnd: (details) {
//                 //     _finishDrawing();
//                 //   },

//                 //   child: Container(color: Colors.transparent),
//                 // ),
//                 Positioned(
//                   left: toolbarX,
//                   top: toolbarY,
//                   child: GestureDetector(
//                     onPanUpdate: (details) {
//                       setState(() {
//                         toolbarX += details.delta.dx;
//                         toolbarY += details.delta.dy;
//                       });
//                     },
//                     onPanEnd: (details) {
//                       const double snapThreshold = 30.0;

//                       double targetY = toolbarY;
//                       double targetX = toolbarX;

//                       if (toolbarY < snapThreshold) {
//                         targetY = 0;
//                         targetX = 0;
//                         capsuleToolbar = false;
//                       } else if (toolbarY >
//                           screenSize.height -
//                               snapThreshold -
//                               padding.top -
//                               kToolbarHeight -
//                               toolbarHeight) {
//                         targetY =
//                             screenSize.height -
//                             toolbarHeight -
//                             padding.top -
//                             kToolbarHeight;
//                         targetX = 0;
//                         capsuleToolbar = false;
//                       } else {
//                         setState(() {
//                           capsuleToolbar = true;
//                         });
//                       }

//                       // if (toolbarX < 0) targetX = 10;
//                       // if (toolbarX > screenSize.width - 300) {
//                       //   targetX = screenSize.width - 310;
//                       // }

//                       if (targetY != toolbarY || targetX != toolbarX) {
//                         _runSnapAnimation(Offset(targetX, targetY));
//                       }
//                     },
//                     child: Container(
//                       key: _toolbarKey,
//                       constraints: BoxConstraints(
//                         maxWidth: (capsuleToolbar)
//                             ? screenSize.width - 40
//                             : screenSize.width,
//                       ),
//                       child: _buildToolBar(viewport, screenSize),
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Offset _toLocal(Offset screenPoint) {
//     final Matrix4 transformMatrix = transformationController.value;

//     final Matrix4 inverseMatrix =
//         Matrix4.tryInvert(transformMatrix) ?? Matrix4.identity();

//     return MatrixUtils.transformPoint(inverseMatrix, screenPoint);
//   }

//   Widget _buildRectangle(
//     HiveShape shape,
//     Rect rect,
//     bool isSelected,
//     bool showControls,
//     double rotation,
//   ) {
//     return Positioned(
//       left: rect.left,
//       top: rect.top,
//       width: rect.width,
//       height: rect.height,
//       child: Transform.rotate(
//         angle: shape.rotation,
//         child: Stack(
//           clipBehavior: Clip.none,
//           children: [
//             Container(
//               decoration: BoxDecoration(
//                 color: (shape.config.fill) ? Color(shape.colorValue) : null,
//                 border: Border.all(
//                   color: isSelected ? Colors.blueAccent : Colors.lightGreen,
//                   width: shape.config.borderWidth,
//                 ),
//                 borderRadius: BorderRadius.circular(shape.config.borderRadius),
//                 shape: BoxShape.rectangle,
//               ),
//             ),

//             // Delete Button
//             Positioned(
//               top: -40 / currentScale,
//               right: -40 / currentScale,
//               child: AnimatedOpacity(
//                 duration: const Duration(milliseconds: 200),
//                 opacity: showControls ? 1.0 : 0.0,
//                 child: Container(
//                   width: 40 / currentScale,
//                   height: 40 / currentScale,
//                   padding: const EdgeInsets.all(4),
//                   decoration: const BoxDecoration(
//                     color: Colors.red,
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(blurRadius: 4, color: Colors.black26),
//                     ],
//                   ),
//                   child: Icon(
//                     Icons.close,
//                     size: (currentScale > 2) ? 5 : 20 / currentScale,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),

//             // Resize Button
//             Positioned(
//               bottom: -40 / currentScale,
//               right: -40 / currentScale,
//               child: AnimatedOpacity(
//                 duration: const Duration(milliseconds: 200),
//                 opacity: showControls ? 1.0 : 0.0,
//                 child: Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     shape: BoxShape.circle,
//                     border: Border.all(color: Colors.blueAccent, width: 2),
//                     boxShadow: const [
//                       BoxShadow(blurRadius: 4, color: Colors.black26),
//                     ],
//                   ),
//                   child: const Icon(
//                     Icons.open_in_full,
//                     size: 18,
//                     color: Colors.blueAccent,
//                   ),
//                 ),
//               ),
//             ),

//             // Rotate Button
//             Positioned(
//               bottom: -40 / currentScale,
//               left: -40 / currentScale,
//               child: AnimatedOpacity(
//                 duration: const Duration(milliseconds: 200),
//                 opacity: showControls ? 1.0 : 0.0,
//                 child: Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     shape: BoxShape.circle,
//                     border: Border.all(color: Colors.blueAccent, width: 2),
//                     boxShadow: const [
//                       BoxShadow(blurRadius: 4, color: Colors.black26),
//                     ],
//                   ),
//                   child: const Icon(
//                     Icons.rotate_left,
//                     size: 18,
//                     color: Colors.blueAccent,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCircle(
//     HiveShape shape,
//     Rect rect,
//     bool isSelected,
//     bool showControls,
//   ) {
//     return Positioned(
//       left: rect.left,
//       top: rect.top,
//       width: rect.width,
//       height: rect.height,
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           Container(
//             decoration: BoxDecoration(
//               color: Color(shape.colorValue),
//               border: Border.all(
//                 color: isSelected ? Colors.blueAccent : Colors.transparent,
//                 width: shape.config.borderWidth,
//               ),
//               shape: BoxShape.circle,
//             ),
//           ),

//           Positioned(
//             top: -40 / currentScale,
//             right: -40 / currentScale,
//             child: AnimatedOpacity(
//               duration: const Duration(milliseconds: 200),
//               opacity: showControls ? 1.0 : 0.0,
//               child: Container(
//                 width: 40 / currentScale,
//                 height: 40 / currentScale,
//                 padding: const EdgeInsets.all(4),
//                 decoration: const BoxDecoration(
//                   color: Colors.red,
//                   shape: BoxShape.circle,
//                   boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
//                 ),
//                 child: Icon(
//                   Icons.close,
//                   size: (currentScale > 2) ? 5 : 20 / currentScale,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildElementOptions() {
//     return ClipRRect(
//       borderRadius: BorderRadiusGeometry.vertical(top: Radius.circular(10)),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//         child: Container(
//           color: Colors.white.withValues(alpha: 0.75),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildElementOption(
//                 "Background Image",
//                 Icons.image_outlined,
//                 () {},
//               ),
//               // _buildElementOption("Fill Color", MyCustomIcons.paintcan, () {}),
//               _buildElementOptionWithPopup(
//                 "Shape Options",
//                 BorderSettingsPopup(
//                   currentConfig: _selectedShape!.shape!.config,
//                   currentPosition: Offset(
//                     _selectedShape!.shape!.shapeStartPoint.dx,
//                     _selectedShape!.shape!.shapeStartPoint.dy,
//                   ),
//                   currentDimensions: Size(
//                     (_selectedShape!.shape!.shapeStartPoint.dx -
//                             _selectedShape!.shape!.shapeEndPoint.dx)
//                         .abs(),
//                     (_selectedShape!.shape!.shapeStartPoint.dy -
//                             _selectedShape!.shape!.shapeEndPoint.dy)
//                         .abs(),
//                   ),
//                   onConfigChanged: (newConfig) {
//                     setState(() {
//                       _selectedShape!.shape!.config = newConfig;
//                     });
//                   },
//                   onDimensionsChanged: (newDimensions) {
//                     final currentShape = _selectedShape!.shape!;

//                     setState(() {
//                       final start = currentShape.shapeStartPoint;
//                       final end = currentShape.shapeEndPoint;

//                       final double safeWidth = newDimensions.width.clamp(
//                         50.0,
//                         1000.0,
//                       );
//                       final double safeHeight = newDimensions.height.clamp(
//                         50.0,
//                         1000.0,
//                       );

//                       final double signX = (end.dx >= start.dx) ? 1.0 : -1.0;
//                       final double signY = (end.dy >= start.dy) ? 1.0 : -1.0;

//                       currentShape.shapeEndPoint = Offset(
//                         start.dx + (safeWidth * signX),
//                         start.dy + (safeHeight * signY),
//                       );
//                     });
//                   },
//                   selectedColor: Color(_selectedShape!.shape!.colorValue),
//                   onColorChanged: (color) => setState(
//                     () => _selectedShape!.shape!.colorValue = color.toARGB32(),
//                   ),
//                 ),
//                 () {},
//               ),

//               _buildElementOption("Edit Shape", Icons.access_alarm, () {}),

//               // _buildElementOption(
//               //   "Border Settings",
//               //   MyCustomIcons.paintcan,
//               //   () {},
//               // ),
//               // _buildElementOption("Size", Icons.change_circle, () {}),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildElementOption(
//     String text,
//     IconData icon,
//     VoidCallback onPressed,
//   ) {
//     return Column(
//       children: [
//         Text(text, style: TextStyle(color: Colors.black)),
//         _buildIconBtn(icon, true, false, onPressed),
//       ],
//     );
//   }

//   Widget _buildElementOptionWithPopup(
//     String text,
//     dynamic popup,
//     VoidCallback onPressed,
//   ) {
//     return Column(
//       children: [
//         Text(text, style: TextStyle(color: Colors.black)),
//         popup,
//       ],
//     );
//   }

//   Widget _buildToolBar(Rect viewport, Size screenSize) {
//     return ClipRRect(
//       borderRadius: (capsuleToolbar)
//           ? BorderRadius.circular(50)
//           : BorderRadius.circular(0),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//         child: Container(
//           height: 40,
//           width: (capsuleToolbar) ? null : screenSize.width,
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
//           decoration: BoxDecoration(
//             color: Colors.white.withValues(alpha: 0.85),
//             borderRadius: (capsuleToolbar) ? BorderRadius.circular(50) : null,
//             border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withValues(alpha: 0.15),
//                 blurRadius: 20,
//                 offset: const Offset(0, 10),
//               ),
//             ],
//           ),
//           child: SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               // mainAxisSize: MainAxisSize.min,
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 GestureDetector(
//                   behavior: HitTestBehavior.translucent,
//                   onPanUpdate: (details) {
//                     setState(() {
//                       toolbarX += details.delta.dx;
//                       toolbarY += details.delta.dy;
//                     });
//                   },
//                   child: Container(
//                     padding: const EdgeInsets.only(right: 12, left: 4),
//                     height: double.infinity,
//                     child: const Icon(
//                       Icons.drag_indicator_rounded,
//                       color: Colors.grey,
//                       size: 24,
//                     ),
//                   ),
//                 ),

//                 Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8.0,
//                     vertical: 8,
//                   ),
//                   child: VerticalDivider(
//                     width: 1,
//                     color: Colors.grey.withValues(alpha: 0.3),
//                   ),
//                 ),

//                 _buildIconBtn(
//                   Icons.undo_rounded,
//                   _actions.isNotEmpty,
//                   false,
//                   () {
//                     setState(() {
//                       final lastAction = _actions.removeLast();
//                       _undoActions.add(lastAction);
//                       if (lastAction.type == ActionType.draw) {
//                         for (var record in lastAction.strokes) {
//                           // _strokes.remove(record.stroke);
//                           _elements.removeWhere((element) {
//                             return element.stroke != null &&
//                                 element.stroke!.id == record.stroke.id;
//                           });
//                         }
//                       } else if (lastAction.type == ActionType.erase) {
//                         for (var record in lastAction.strokes) {
//                           if (record.index <= _strokes.length) {
//                             // _strokes.insert(record.index, record.stroke);
//                             _elements.insert(
//                               record.index,
//                               CanvasElement(stroke: record.stroke),
//                             );
//                           } else {
//                             _elements.add(CanvasElement(stroke: record.stroke));
//                             // _strokes.add(record.stroke);
//                           }
//                         }
//                       } else if (lastAction.type == ActionType.addElement) {
//                         for (var record in lastAction.shapes) {
//                           _elements.removeWhere((element) {
//                             if (_selectedShape!.shape!.id == element.shape!.id)
//                               _selectedShape = null;
//                             return element.shape != null &&
//                                 element.shape!.id == record.shape.id;
//                           });
//                         }
//                       }
//                     });
//                   },
//                 ),

//                 _buildIconBtn(
//                   Icons.redo_rounded,
//                   _undoActions.isNotEmpty,
//                   false,
//                   () {
//                     setState(() {
//                       final action = _undoActions.removeLast();
//                       _actions.add(action);
//                       if (action.type == ActionType.draw) {
//                         for (var record in action.strokes) {
//                           // _strokes.add(record.stroke);
//                           _elements.add(CanvasElement(stroke: record.stroke));
//                         }
//                       } else if (action.type == ActionType.erase) {
//                         for (var record in action.strokes) {
//                           // _strokes.remove(record.stroke);
//                           _elements.removeWhere((element) {
//                             return element.stroke != null &&
//                                 element.stroke!.id == record.stroke.id;
//                           });
//                         }
//                       } else if (action.type == ActionType.addElement) {
//                         for (var record in action.shapes) {
//                           _elements.insert(
//                             record.index,
//                             CanvasElement(shape: record.shape),
//                           );
//                         }
//                       }
//                     });
//                   },
//                 ),

//                 Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8.0,
//                     vertical: 8,
//                   ),
//                   child: VerticalDivider(
//                     width: 1,
//                     color: Colors.grey.withValues(alpha: 0.3),
//                   ),
//                 ),

//                 PenSettingsButton(
//                   key: _penButtonKey,
//                   currentSize: _selectedSize,
//                   currentColor: _selectedColor,
//                   penButtonKey: _penButtonKey,
//                   isSelected: _currentDrawMode == CanvasDrawMode.brush,
//                   setSelected: () {
//                     setState(() {
//                       _currentDrawMode = CanvasDrawMode.brush;
//                     });
//                   },
//                   onSizeChanged: (newSize) {
//                     setState(() => _selectedSize = newSize);
//                   },
//                   onColorChanged: (newColor) {
//                     setState(() {
//                       _selectedColor = newColor;
//                       _currentDrawMode == CanvasDrawMode.brush;
//                     });
//                   },
//                 ),

//                 _buildIconBtn(
//                   Icons.delete,
//                   true,
//                   _currentDrawMode == CanvasDrawMode.eraser,
//                   () {
//                     setState(() {
//                       _currentDrawMode = CanvasDrawMode.eraser;
//                     });
//                   },
//                 ),

//                 // SizedBox(
//                 //   width: 120,
//                 //   child: Column(
//                 //     mainAxisAlignment: MainAxisAlignment.center,
//                 //     children: [
//                 //       // Text("${_selectedSize.toInt()} px", style: TextStyle(fontSize: 8, color: Colors.grey)),
//                 //       SliderTheme(
//                 //         data: SliderTheme.of(context).copyWith(
//                 //           trackHeight: 4.0,
//                 //           thumbShape: const RoundSliderThumbShape(
//                 //             enabledThumbRadius: 6.0,
//                 //           ),
//                 //           overlayShape: const RoundSliderOverlayShape(
//                 //             overlayRadius: 14.0,
//                 //           ),
//                 //           activeTrackColor: Colors.black87,
//                 //           inactiveTrackColor: Colors.grey,
//                 //           thumbColor: Colors.black87,
//                 //         ),
//                 //         child: Slider(
//                 //           value: _selectedSize,
//                 //           min: 1.0,
//                 //           max: 100.0,
//                 //           onChanged: (value) =>
//                 //               setState(() => _selectedSize = value),
//                 //         ),
//                 //       ),
//                 //     ],
//                 //   ),
//                 // ),
//                 const SizedBox(width: 8),

//                 ColorCircle(
//                   selectedColor: _selectedColor,
//                   onTap: () {
//                     ColorCircle.showColorPickerDialog(
//                       selectedColor: _selectedColor,
//                       context: context,
//                       onColorChanged: (color) => setState(() {
//                         _currentDrawMode == CanvasDrawMode.brush;
//                         _selectedColor = color;
//                       }),
//                     );
//                   },
//                 ),

//                 // GestureDetector(
//                 //   onTap: () {
//                 //     showDialog(
//                 //       context: context,
//                 //       builder: (context) => AlertDialog(
//                 //         title: const Text("Pick a Color"),
//                 //         content: SingleChildScrollView(
//                 //           child: ColorPicker(
//                 //             pickerColor: _selectedColor,
//                 //             onColorChanged: (color) {
//                 //               setState(() {
//                 //                 _currentDrawMode == CanvasDrawMode.brush;
//                 //                 _selectedColor = color;
//                 //               });
//                 //             },
//                 //           ),
//                 //         ),
//                 //         actions: [
//                 //           TextButton(
//                 //             onPressed: () => Navigator.of(context).pop(),
//                 //             child: const Text("Done"),
//                 //           ),
//                 //         ],
//                 //       ),
//                 //     );
//                 //   },
//                 //   child: Container(
//                 //     width: 36,
//                 //     height: 36,
//                 //     decoration: BoxDecoration(
//                 //       color: _selectedColor,
//                 //       shape: BoxShape.circle,
//                 //       border: Border.all(
//                 //         color: Colors.grey.withValues(alpha: 0.3),
//                 //         width: 2,
//                 //       ),
//                 //       boxShadow: [
//                 //         BoxShadow(
//                 //           color: _selectedColor.withValues(alpha: 0.4),
//                 //           blurRadius: 8,
//                 //           offset: const Offset(0, 2),
//                 //         ),
//                 //       ],
//                 //     ),
//                 //   ),
//                 // ),

//                 // _buildIconBtn(Icons.link, true, () {
//                 //   setState(() {
//                 //     _linkMenuEnabled = !_linkMenuEnabled;
//                 //   });
//                 // }),
//                 LinkMenuPopup(
//                   key: _linkMenuKey,
//                   addImage: () {
//                     _addImage(viewport);
//                   },
//                   addDocument: () {
//                     _addDocument(viewport);
//                   },
//                   linkMenuKey: _linkMenuKey,
//                 ),

//                 ShapeMenuPopup(
//                   key: _shapeButtonKey,
//                   currentConfig: _currentShapeConfig,
//                   isSelected: _currentDrawMode == CanvasDrawMode.shape,
//                   shapeToolKey: _shapeButtonKey,
//                   // screenSize: screenSize,
//                   setSelected: () {
//                     setState(() {
//                       _currentDrawMode = CanvasDrawMode.shape;
//                     });
//                   },
//                   onConfigChanged: (newConfig) {
//                     setState(() {
//                       _currentShapeConfig = newConfig;
//                       _currentShape = newConfig.shapeType;
//                       // switch (_currentShapeConfig.shapeTypeEnum) {
//                       //   case ShapeTypeEnum.rectangle:
//                       //     _currentShape = ShapeType.rectangle;
//                       //     break;
//                       //   case ShapeTypeEnum.circle:
//                       //     _currentShape = ShapeType.circle;
//                       //     break;
//                       //   case ShapeTypeEnum.triangle:
//                       //     _currentShape = ShapeType.rectangle;
//                       //     break;
//                       //   case ShapeTypeEnum.line:
//                       //     _currentShape = ShapeType.rectangle;
//                       //     break;
//                       // }
//                     });
//                   },
//                 ),

//                 // ShapeMenuPopup(
//                 //   addRectangle: () {
//                 //     setState(() {
//                 //       _currentShape = ShapeType.rectangle;
//                 //     });
//                 //   },
//                 //   addCircle: () {
//                 //     setState(() {
//                 //       _currentShape = ShapeType.circle;
//                 //     });
//                 //   },
//                 // ),
//                 _buildIconBtn(
//                   (_canvasMode == CanvasMode.edit)
//                       ? Icons.back_hand
//                       : Icons.draw_rounded,
//                   true,
//                   false,
//                   () {
//                     setState(() {
//                       switch (_canvasMode) {
//                         case CanvasMode.draw:
//                           _canvasMode = CanvasMode.edit;
//                           break;
//                         case CanvasMode.edit:
//                           _canvasMode = CanvasMode.draw;
//                           break;
//                       }
//                     });
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildIconBtn(
//     IconData icon,
//     bool isEnabled,
//     bool isSelected,
//     VoidCallback onPressed,
//   ) {
//     return IconButton(
//       icon: Icon(icon, size: 22),
//       color: Colors.black87,
//       isSelected: isSelected,
//       style: ButtonStyle(
//         backgroundColor: WidgetStateProperty.resolveWith((
//           Set<WidgetState> states,
//         ) {
//           if (states.contains(WidgetState.selected)) {
//             return Colors.black26;
//           }
//           return Colors.transparent;
//         }),
//       ),
//       disabledColor: Colors.grey.withValues(alpha: 0.4),
//       onPressed: isEnabled ? onPressed : null,
//       constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
//       padding: EdgeInsets.zero,
//     );
//   }

//   void _addImage(Rect viewport) async {
//     final ImagePicker picker = ImagePicker();

//     final XFile? image = await picker.pickImage(source: ImageSource.gallery);
//     if (image == null) return;

//     final String id = DateTime.now().millisecondsSinceEpoch.toString();
//     final directory = await getApplicationDocumentsDirectory();
//     final String destinationPath = p.join(directory.path, id);
//     final sourceFilePath = image.path;
//     final File finalFile = await File(sourceFilePath).copy(destinationPath);
//     final permanentFilePath = finalFile.path;

//     if (await File(sourceFilePath).exists()) {
//       await File(sourceFilePath).delete();
//     }

//     final Uint8List bytes = await finalFile.readAsBytes();
//     final ui.Image decodedImage = await decodeImageFromList(bytes);
//     double height = decodedImage.height.toDouble();
//     double width = decodedImage.width.toDouble();
//     final double aspectRatio = width / height;
//     width = 200;
//     height = width / aspectRatio;

//     MovableElement movableElement = MovableElement(
//       width: width,
//       height: height,
//       id: id,
//       aspectRatio: aspectRatio,
//       type: ElementType.image,
//       position: viewport.center,
//       filePath: permanentFilePath,
//       widget: _buildImageWidget(permanentFilePath, id, width, height),
//     );

//     widget.folderService.createFile(parentId: id, filePath: permanentFilePath);
//     widget.folderService.createMovableElement(movableElement: movableElement);

//     setState(() {
//       _images.add(movableElement);
//       _elements.add(CanvasElement(movableElement: movableElement.toData()));
//     });
//   }

//   void _addDocument(Rect viewport) async {
//     final FilePicker picker = FilePicker.platform;

//     final FilePickerResult? result = await picker.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['pdf'],
//       allowMultiple: false,
//     );

//     if (result != null && result.files.isNotEmpty) {
//       final file = result.files.first;
//       final String id = '${DateTime.now().millisecondsSinceEpoch}.pdf';
//       final directory = await getApplicationDocumentsDirectory();
//       final String destinationPath = p.join(directory.path, id);
//       final sourceFilePath = file.path!;
//       final File finalFile = await File(sourceFilePath).copy(destinationPath);
//       final permanentFilePath = finalFile.path;

//       if (await File(sourceFilePath).exists()) {
//         await File(sourceFilePath).delete();
//       }

//       final movableElement = MovableElement(
//         width: 200,
//         height: 120,
//         id: id,
//         type: ElementType.document,
//         position: viewport.center,
//         filePath: permanentFilePath,
//         aspectRatio: 200 / 120,
//         title: file.name,
//         widget: _buildDocumentWidget(
//           permanentFilePath,
//           file.name,
//           id,
//           200,
//           120,
//         ),
//       );

//       widget.folderService.createFile(
//         parentId: id,
//         filePath: permanentFilePath,
//       );

//       widget.folderService.createMovableElement(movableElement: movableElement);

//       setState(() {
//         _documents.add(movableElement);
//       });
//     }
//   }

//   Widget _buildImageWidget(
//     String imagePath,
//     String id,
//     double width,
//     double height,
//   ) {
//     return SizedBox(
//       width: double.infinity,
//       height: double.infinity,
//       child: Stack(
//         alignment: Alignment.center,
//         clipBehavior: Clip.none,
//         children: [
//           SizedBox(
//             width: double.infinity,
//             height: double.infinity,
//             child: Image.file(File(imagePath), fit: BoxFit.fill),
//           ),
//           // Positioned(
//           //   top: 0,
//           //   right: 0,
//           //   child: IconButton(
//           //     onPressed: () async {
//           //       if (await File(imagePath).exists()) {
//           //         await File(imagePath).delete();
//           //       }
//           //       setState(() {
//           //         _images.removeWhere((element) => element.id == id);
//           //       });
//           //     },
//           //     icon: const Icon(Icons.close, color: Colors.red, size: 26),
//           //   ),
//           // ),

//           // // Bottom Right
//           // Positioned(
//           //   right: 0,
//           //   bottom: 0,
//           //   child: GestureDetector(
//           //     onPanUpdate: (details) {
//           //       final element = _images.firstWhere((e) => e.id == id);
//           //       final newWidth = element.width + details.delta.dx;
//           //       final newHeight = element.height + details.delta.dy;

//           //       if (newWidth > 50 && newHeight > 50) {
//           //         setState(() {
//           //           element.width = newWidth;
//           //           element.height = newHeight;
//           //           element.widget = _buildImageWidget(
//           //             imagePath,
//           //             id,
//           //             newWidth,
//           //             newHeight,
//           //           );
//           //         });
//           //       }
//           //     },
//           //     child: Container(
//           //       width: 10,
//           //       height: 10,
//           //       decoration: BoxDecoration(
//           //         color: Colors.white,
//           //         shape: BoxShape.circle,
//           //       ),
//           //     ),
//           //   ),
//           // ),

//           // // Bottom Left
//           // Positioned(
//           //   left: 0,
//           //   bottom: 0,
//           //   child: GestureDetector(
//           //     onPanUpdate: (details) {
//           //       final element = _images.firstWhere((e) => e.id == id);
//           //       final newWidth = element.width - details.delta.dx;
//           //       final newHeight = element.height + details.delta.dy;

//           //       if (newWidth > 50 && newHeight > 50) {
//           //         setState(() {
//           //           element.width = newWidth;
//           //           element.height = newHeight;
//           //           element.position = Offset(
//           //             element.position.dx + details.delta.dx,
//           //             element.position.dy,
//           //           );

//           //           element.widget = _buildImageWidget(
//           //             imagePath,
//           //             id,
//           //             newWidth,
//           //             newHeight,
//           //           );
//           //         });
//           //       }
//           //     },
//           //     child: Container(
//           //       width: 10,
//           //       height: 10,
//           //       decoration: BoxDecoration(
//           //         color: Colors.white,
//           //         shape: BoxShape.circle,
//           //       ),
//           //     ),
//           //   ),
//           // ),

//           // // Top Left
//           // Positioned(
//           //   left: 0,
//           //   top: 0,
//           //   child: GestureDetector(
//           //     onPanUpdate: (details) {
//           //       final element = _images.firstWhere((e) => e.id == id);
//           //       final newWidth = element.width - details.delta.dx;
//           //       final newHeight = element.height - details.delta.dy;

//           //       if (newWidth > 50 && newHeight > 50) {
//           //         setState(() {
//           //           element.width = newWidth;
//           //           element.height = newHeight;
//           //           element.position = Offset(
//           //             element.position.dx + details.delta.dx,
//           //             element.position.dy + details.delta.dy,
//           //           );

//           //           element.widget = _buildImageWidget(
//           //             imagePath,
//           //             id,
//           //             newWidth,
//           //             newHeight,
//           //           );
//           //         });
//           //       }
//           //     },
//           //     child: Container(
//           //       width: 10,
//           //       height: 10,
//           //       decoration: BoxDecoration(
//           //         color: Colors.white,
//           //         shape: BoxShape.circle,
//           //       ),
//           //     ),
//           //   ),
//           // ),

//           // // Top Right
//           // Positioned(
//           //   right: 0,
//           //   top: 0,
//           //   child: GestureDetector(
//           //     onPanUpdate: (details) {
//           //       final element = _images.firstWhere((e) => e.id == id);
//           //       final newWidth = element.width + details.delta.dx;
//           //       final newHeight = element.height - details.delta.dy;

//           //       if (newWidth > 50 && newHeight > 50) {
//           //         setState(() {
//           //           element.width = newWidth;
//           //           element.height = newHeight;
//           //           element.position = Offset(
//           //             element.position.dx,
//           //             element.position.dy + details.delta.dy,
//           //           );

//           //           element.widget = _buildImageWidget(
//           //             imagePath,
//           //             id,
//           //             newWidth,
//           //             newHeight,
//           //           );
//           //         });
//           //       }
//           //     },
//           //     child: Container(
//           //       width: 10,
//           //       height: 10,
//           //       decoration: BoxDecoration(
//           //         color: Colors.white,
//           //         shape: BoxShape.circle,
//           //       ),
//           //     ),
//           //   ),
//           // ),
//         ],
//       ),
//     );
//   }

//   List<Widget> _buildCanvasLayers(Rect viewport) {
//     List<Widget> layers = [];
//     List<CanvasElement> strokeBuffer = [];

//     for (int i = 0; i < _elements.length; i++) {
//       final element = _elements[i];

//       if (element.stroke != null) {
//         // It's a stroke! Don't draw yet, just add to buffer.
//         strokeBuffer.add(element);
//       } else {
//         // It's a Widget (Shape or Image)!

//         // 1. FLUSH: If we have pending strokes below this shape, draw them now.
//         if (strokeBuffer.isNotEmpty) {
//           layers.add(
//             // RepaintBoundary is crucial here for performance!
//             RepaintBoundary(
//               child: CustomPaint(
//                 size: Size.infinite,
//                 // Create a painter for ONLY these specific strokes
//                 painter: ElementsPainter(
//                   elements: List.from(strokeBuffer),
//                   viewport: viewport,
//                 ),
//               ),
//             ),
//           );
//           strokeBuffer.clear(); // Reset buffer
//         }

//         // 2. DRAW WIDGET: Add the shape/image on top of the strokes
//         if (element.shape != null) {
//           layers.add(_buildShape(element));
//         } else if (element.movableElement != null) {
//           if (element.movableElement!.type == ElementType.image) {
//             layers.add(
//               _buildImage(
//                 _images.firstWhere(
//                   (image) => image.id == element.movableElement!.id,
//                 ),
//               ),
//             );
//           }
//         }
//       }
//     }

//     // 3. FINAL FLUSH: Draw any remaining strokes on top of the last shape
//     if (strokeBuffer.isNotEmpty) {
//       layers.add(
//         RepaintBoundary(
//           child: CustomPaint(
//             size: Size.infinite,
//             painter: ElementsPainter(
//               elements: strokeBuffer,
//               viewport: viewport,
//             ),
//           ),
//         ),
//       );
//     }

//     return layers;
//   }

//   Widget _buildShape(CanvasElement element) {
//     final HiveShape shape = element.shape!;
//     final rect = Rect.fromPoints(shape.shapeStartPoint, shape.shapeEndPoint);
//     final bool isSelected = (_selectedShape == element);
//     final showControls = isSelected && !_isDraggingShape;
//     final double degrees = (shape.rotation * 180 / Math.pi);
//     final double normalizedDegrees = (degrees % 360 + 360) % 360;

//     switch (shape!.type) {
//       case ShapeType.rectangle:
//         return _buildRectangle(
//           shape,
//           rect,
//           isSelected,
//           showControls,
//           normalizedDegrees,
//         );
//       case ShapeType.circle:
//         return _buildCircle(shape, rect, isSelected, showControls);
//       case ShapeType.triangle:
//         // TODO: Handle this case.
//         throw UnimplementedError();
//       case ShapeType.line:
//         // TODO: Handle this case.
//         throw UnimplementedError();
//     }
//   }

//   Widget _buildImage(MovableElement element) {
//     final isSelected = _selectedElement == element;
//     final showControls = isSelected && !_isDraggingElement;
//     final double degrees = (element.rotation * 180 / Math.pi);
//     final double normalizedDegrees = (degrees % 360 + 360) % 360;

//     return Positioned(
//       left: element.position.dx,
//       top: element.position.dy,
//       child: Transform.rotate(
//         angle: element.rotation,
//         alignment: Alignment.center,
//         child: Stack(
//           clipBehavior: Clip.none,
//           children: [
//             Container(
//               width: element.width,
//               height: element.height,
//               decoration: BoxDecoration(
//                 border: Border.all(
//                   color: isSelected ? Colors.blueAccent : Colors.transparent,
//                   width: 2,
//                 ),
//               ),
//               child: element.widget,
//             ),

//             if (isSelected && _isRotatingMovableElement)
//               Positioned(
//                 top: element.height / 2,
//                 left: element.width / 2,
//                 child: FractionalTranslation(
//                   translation: const Offset(-0.5, -0.5),
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(5),
//                       color: const Color.fromARGB(150, 0, 0, 0),
//                     ),
//                     child: Text(
//                       "${normalizedDegrees.toStringAsFixed(1)}°",
//                       style: const TextStyle(color: Colors.white, fontSize: 12),
//                     ),
//                   ),
//                 ),
//               ),

//             // Delete Button
//             // Delete Button
//             // Delete Button
//             // Delete Button
//             Positioned(
//               top: -15,
//               right: -15,
//               child: AnimatedOpacity(
//                 duration: const Duration(milliseconds: 200),
//                 opacity: showControls ? 1.0 : 0.0,
//                 child: Container(
//                   width: 40,
//                   height: 40,
//                   padding: const EdgeInsets.all(4),
//                   decoration: const BoxDecoration(
//                     color: Colors.red,
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(blurRadius: 4, color: Colors.black26),
//                     ],
//                   ),
//                   child: const Icon(Icons.close, size: 18, color: Colors.white),
//                 ),
//               ),
//             ),

//             Positioned(
//               bottom: -15,
//               right: -15,
//               child: AnimatedOpacity(
//                 duration: const Duration(milliseconds: 200),
//                 opacity: showControls ? 1.0 : 0.0,
//                 child: Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     shape: BoxShape.circle,
//                     border: Border.all(color: Colors.blueAccent, width: 2),
//                     boxShadow: const [
//                       BoxShadow(blurRadius: 4, color: Colors.black26),
//                     ],
//                   ),
//                   child: const Icon(
//                     Icons.open_in_full,
//                     size: 18,
//                     color: Colors.blueAccent,
//                   ),
//                 ),
//               ),
//             ),

//             Positioned(
//               bottom: -15,
//               left: -15,
//               child: AnimatedOpacity(
//                 duration: const Duration(milliseconds: 200),
//                 opacity: showControls ? 1.0 : 0.0,
//                 child: Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     shape: BoxShape.circle,
//                     border: Border.all(color: Colors.blueAccent, width: 2),
//                     boxShadow: const [
//                       BoxShadow(blurRadius: 4, color: Colors.black26),
//                     ],
//                   ),
//                   child: const Icon(
//                     Icons.rotate_left,
//                     size: 18,
//                     color: Colors.blueAccent,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDocumentWidget(
//     String filePath,
//     String name,
//     String id,
//     double width,
//     double height,
//   ) {
//     return Container(
//       constraints: BoxConstraints(maxWidth: 300),
//       color: Colors.amber,
//       child: Center(
//         child: Text(
//           name,
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             color: Colors.white,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ),
//     );
//   }

//   void _startDrawing(Offset position) {
//     if (_isPanMode || _isTwoFingersDown) return;

//     _currentPoints = [position];

//     if (_currentDrawMode == CanvasDrawMode.eraser) {
//       setState(() {
//         eraserPoint = position;
//         _eraseAt(position);
//       });
//       return;
//     }

//     _updateCurrentPaint();
//     Path newPath = Path();

//     setState(() {
//       eraserPoint = position;
//       _currentPath = newPath;
//       if (_currentDrawMode == CanvasDrawMode.shape &&
//           _previousPointersCount == 0) {
//         if (_shapeStartPoint != null) {
//           setState(() {
//             _shapeEndPoint = null;
//             _shapeStartPoint = null;
//           });
//           return;
//         }
//         _shapeStartPoint = position;
//       }
//     });
//   }

//   Offset _screenToCanvas(Offset screenPoint) {
//     final matrix = transformationController.value;
//     final inverseMatrix = Matrix4.inverted(matrix);
//     return MatrixUtils.transformPoint(inverseMatrix, screenPoint);
//   }

//   Rect _calculateViewport(Size screenSize) {
//     final matrix = transformationController.value;
//     final inverse = Matrix4.inverted(matrix);

//     final topLeft = MatrixUtils.transformPoint(inverse, Offset.zero);
//     final bottomRight = MatrixUtils.transformPoint(
//       inverse,
//       Offset(screenSize.width, screenSize.height),
//     );

//     return Rect.fromPoints(topLeft, bottomRight);
//   }

//   bool _isEraserTouchingPath(
//     HiveStroke stroke,
//     Offset eraserCenter,
//     double eraserRadius,
//   ) {
//     final metrics = stroke.path.computeMetrics();

//     final hitThreshold = eraserRadius + (stroke.paint.strokeWidth / 2);

//     double totalPathLength = 0.0;

//     for (final metric in metrics) {
//       totalPathLength += metric.length;

//       final double step = 5.0;
//       for (double i = 0; i < metric.length; i += step) {
//         final tangent = metric.getTangentForOffset(i);
//         if (tangent == null) continue;

//         final pathPoint = tangent.position;

//         if ((pathPoint - eraserCenter).distance <= hitThreshold) {
//           return true;
//         }
//       }
//     }

//     if (totalPathLength < 5.0) {
//       final bounds = stroke.bounds;
//       if ((bounds.center - eraserCenter).distance <= hitThreshold) {
//         return true;
//       }
//     }

//     return false;
//   }

//   void _eraseAt(Offset point) {
//     final double eraserRadius = 40.0 / 2;

//     final safeEraserRect = Rect.fromCenter(
//       center: point,
//       width: 40.0 + 100,
//       height: 40.0 + 100,
//     );

//     final elementsToRemove = _elements.where((element) {
//       if (element.stroke == null) return false;
//       final stroke = element.stroke!;
//       if (!stroke.bounds.overlaps(safeEraserRect)) return false;
//       return _isEraserTouchingPath(stroke, point, eraserRadius);
//     }).toList();

//     if (elementsToRemove.isEmpty) return;

//     setState(() {
//       for (final element in elementsToRemove) {
//         final stroke = element.stroke!;
//         int index = _strokes.indexOf(stroke);
//         _erasedBatch.add(StrokeRecord(stroke, index));
//       }

//       _elements.removeWhere((s) => elementsToRemove.contains(s));
//     });
//   }

//   void _finishErasing() {
//     if (_erasedBatch.isNotEmpty) {
//       _actions.add(
//         CanvasAction(
//           type: ActionType.erase,
//           strokes: List.from(_erasedBatch),
//           shapes: [],
//         ),
//       );
//       _erasedBatch.clear();
//       _undoActions.clear();
//     }
//   }

//   void _abortStroke() {
//     setState(() {
//       if (_currentPath != null) {
//         _strokeAborted = true;
//         // _strokes.remove(lastStroke);
//         _elements.removeWhere(
//           (element) => element.stroke != null && element.stroke == lastStroke,
//         );
//         _currentPath = null;
//         _previousPoint = null;
//       }
//     });
//   }

//   void _updateDrawing(Offset details) {
//     // final currentPoint = details.localPosition;
//     final currentPoint = _screenToCanvas(details);
//     if (_currentPoints.isNotEmpty) {
//       final lastPoint = _currentPoints.last;
//       // Only add the point if the finger moved more than 2 pixels
//       if ((currentPoint - lastPoint).distance > 2.0) {
//         _currentPoints.add(currentPoint);
//       }
//     } else {
//       _currentPoints.add(currentPoint);
//     }
//     // _currentPoints.add(currentPoint);
//     eraserPoint = currentPoint;

//     if (_currentDrawMode == CanvasDrawMode.eraser) {
//       setState(() {
//         _eraseAt(currentPoint);
//       });
//     } else if (_currentDrawMode == CanvasDrawMode.shape) {
//       setState(() {
//         _shapeEndPoint = currentPoint;
//       });
//     } else {
//       // _previousPoint ??= currentPoint;
//       if (_previousPoint == null && !_strokeAborted) {
//         _strokes = List.from(
//           _strokes..add(
//             HiveStroke(
//               colorValue: _selectedColor.toARGB32(),
//               points: List.from(_currentPoints),
//               size: _selectedSize,
//               type: _strokeType,
//             ),
//           ),
//         );

//         _elements = _elements
//           ..add(
//             CanvasElement(
//               stroke: HiveStroke(
//                 colorValue: _selectedColor.toARGB32(),
//                 points: List.from(_currentPoints),
//                 size: _selectedSize,
//                 type: _strokeType,
//               ),
//             ),
//           );

//         _previousPoint = currentPoint;
//       }

//       if (!_strokeAborted) {
//         _previousPoint = currentPoint;
//       }

//       setState(() {
//         if (!_strokeAborted) {
//           // _strokes.last = HiveStroke(
//           //   colorValue: _selectedColor.value,
//           //   points: List.from(_currentPoints),
//           //   size: _selectedSize,
//           //   type: _strokeType,
//           // );

//           lastStroke = HiveStroke(
//             colorValue: _selectedColor.toARGB32(),
//             points: List.from(_currentPoints),
//             size: _selectedSize,
//             type: _strokeType,
//           );

//           _elements.last = CanvasElement(stroke: lastStroke);
//         }
//       });
//     }
//   }

//   void _finishDrawing(Offset position) {
//     _finishErasing();

//     setState(() {
//       eraserPoint = null;
//     });

//     if (_previousPoint != null) {
//       // final Path dotPath = _drawDot(position);
//       setState(() {
//         // _currentPath!.lineTo(_previousPoint!.dx, _previousPoint!.dy);
//         if (_currentPath != null &&
//             !_strokeAborted &&
//             _currentDrawMode == CanvasDrawMode.brush) {
//           lastStroke = _elements.last.stroke!;
//           _actions.add(
//             CanvasAction(
//               type: ActionType.draw,
//               strokes: [StrokeRecord(lastStroke!, _elements.length - 1)],
//               shapes: [],
//             ),
//           );
//         }

//         // _strokes = List.from(
//         //   _strokes..add(
//         //     HiveStroke(
//         //       colorValue: _selectedColor.value,
//         //       points: List.from(_currentPoints),
//         //       size: _selectedSize,
//         //       type: _strokeType
//         //     ),
//         //   ),
//         // );

//         _undoActions.clear();
//       });
//     } else if (_currentDrawMode == CanvasDrawMode.brush &&
//         _previousPointersCount == 1) {
//       if (_currentPath != null && !_strokeAborted) {
//         // _strokes = _strokes
//         //   ..add(
//         //     HiveStroke(
//         //       colorValue: _selectedColor.value,
//         //       points: List.from(_currentPoints),
//         //       size: _selectedSize,
//         //       type: _strokeType,
//         //     ),
//         //   );

//         lastStroke = HiveStroke(
//           colorValue: _selectedColor.toARGB32(),
//           points: List.from(_currentPoints),
//           size: _selectedSize,
//           type: _strokeType,
//         );

//         _elements = _elements..add(CanvasElement(stroke: lastStroke));

//         _actions.add(
//           CanvasAction(
//             type: ActionType.draw,
//             strokes: [StrokeRecord(lastStroke!, _elements.length - 1)],
//             shapes: [],
//           ),
//         );
//       }

//       _undoActions.clear();
//     } else if (_currentDrawMode == CanvasDrawMode.shape &&
//         _previousPointersCount == 1) {
//       if (_shapeStartPoint == null || _shapeEndPoint == null) return;
//       final double dx = (_shapeStartPoint! - _shapeEndPoint!).dx;
//       final double dy = (_shapeStartPoint! - _shapeEndPoint!).dy;
//       if (dx.abs() < 50 || dy.abs() < 50) {
//         _shapeStartPoint = null;
//         _shapeEndPoint = null;
//         return;
//       }

//       final Paint shapePaint = Paint()
//         ..color = Colors.cyan
//         ..style = PaintingStyle.fill;

//       final shape = HiveShape(
//         points: [],
//         colorValue: _selectedColor.value,
//         size: _selectedSize,
//         type: _currentShape!,
//         shapeStartPoint: _shapeStartPoint!,
//         shapeEndPoint: _shapeEndPoint!,
//       );
//       _elements.add(CanvasElement(shape: shape));

//       _actions.add(
//         CanvasAction(
//           type: ActionType.addElement,
//           strokes: [],
//           shapes: [ShapeRecord(shape, _currentShape!, _elements.length - 1)],
//           shapeStartPoint: _shapeStartPoint,
//           shapeEndPoint: _shapeEndPoint,
//           paint: shapePaint,
//         ),
//       );

//       _shapeStartPoint = null;
//       _shapeEndPoint = null;

//       _undoActions.clear();
//     }
//     _currentPath = null;
//     _previousPoint = null;
//     _strokeAborted = false;
//     lastStroke = null;
//   }

//   void _handleDrawModeDown(Offset point) {
//     _selectedElement = null;

//     if (_pointersCount == 1) {
//       _isDrawing = true;
//       _startDrawing(point);
//     } else {
//       if (_shapeStartPoint != null || _shapeEndPoint != null) {
//         setState(() {
//           _shapeEndPoint = null;
//           _shapeStartPoint = null;
//         });
//         return;
//       }
//     }
//   }

//   void _handleDrawModeMove(PointerMoveEvent event) {
//     if (_isDrawing) {
//       _updateDrawing(event.localPosition);
//     }
//   }

//   void _handleDrawModeUp(PointerUpEvent event) {
//     if (_isDrawing) {
//       _isDrawing = false;
//       _finishDrawing(event.localPosition);
//     } else {
//       if (_shapeStartPoint != null || _shapeEndPoint != null) {
//         setState(() {
//           _shapeEndPoint = null;
//           _shapeStartPoint = null;
//         });
//         return;
//       }
//     }
//   }

//   void _handleEditModeDown(Offset point) {
//     _isDrawing = false;

//     if (_selectedElement != null) {
//       if (_selectedElement!.containsResize(point)) {
//         _isResizingMovableElement = true;

//         _initialCenter = Offset(
//           _selectedElement!.position.dx + _selectedElement!.width / 2,
//           _selectedElement!.position.dy + _selectedElement!.height / 2,
//         );

//         _resizeAnchor = _selectedElement!.getCorners();

//         return;
//       }
//       if (_selectedElement!.containsDelete(point)) {
//         _isDeletingMovableElement = true;
//         return;
//       }
//       if (_selectedElement!.containsRotate(point)) {
//         _isRotatingMovableElement = true;

//         _initialCenter = Offset(
//           _selectedElement!.position.dx + _selectedElement!.width / 2,
//           _selectedElement!.position.dy + _selectedElement!.height / 2,
//         );

//         _initialTouchAngle = Math.atan2(
//           point.dy - _initialCenter.dy,
//           point.dx - _initialCenter.dx,
//         );

//         _initialRotation = _selectedElement!.rotation;

//         return;
//       }
//     } else if (_selectedShape != null) {
//       if (_selectedShape!.containsDelete(point, currentScale)) {
//         _isDeletingShape = true;
//         return;
//       } else if (_selectedShape!.containsResize(point, currentScale)) {
//         _isResizingShape = true;
//         return;
//       } else if (_selectedShape!.containsRotate(point, currentScale)) {
//         _isRotatingShape = true;

//         _initialCenter = Offset(
//           _selectedShape!.shape!.shapeStartPoint.dx +
//               _selectedShape!.shape!.shapeEndPoint.dx / 2,
//           _selectedShape!.shape!.shapeStartPoint.dy +
//               _selectedShape!.shape!.shapeEndPoint.dy / 2,
//         );

//         _initialTouchAngle = Math.atan2(
//           point.dy - _initialCenter.dy,
//           point.dx - _initialCenter.dx,
//         );

//         _initialRotation = _selectedShape!.shape!.rotation;

//         return;
//       }
//     }

//     MovableElement? hitElement;
//     CanvasElement? hitShape;
//     for (CanvasElement element in _elements.reversed) {
//       if (element.shape != null && element.contains(point)) {
//         hitShape = element;
//         break;
//       } else if (element.movableElement != null &&
//           _images
//               .firstWhere((image) => image.id == element.movableElement!.id)
//               .contains(point)) {
//         hitElement = _images.firstWhere(
//           (image) => image.id == element.movableElement!.id,
//         );
//         break;
//       }
//       // if (element.contains(point)) {
//       //   hitShape = element;
//       //   break;
//       // }
//     }

//     // for (var element in _images.reversed) {
//     //   if (hitShape != null) break;
//     //   if (element.contains(point)) {
//     //     hitElement = element;
//     //     break;
//     //   }
//     // }

//     for (var element in _documents.reversed) {
//       if (hitShape != null) break;
//       if (element.contains(point)) {
//         hitElement = element;
//         break;
//       }
//     }

//     if (hitElement != null) {
//       _selectedShape = null;
//       _isDraggingShape = false;
//       _selectedElement = hitElement;
//       _isDraggingElement = true;
//     } else if (hitShape != null) {
//       _selectedElement = null;
//       _isDraggingElement = false;
//       _selectedShape = hitShape;
//       _isDraggingShape = true;
//     } else {
//       _selectedShape = null;
//       _selectedElement = null;
//       _isDraggingShape = false;
//       _isDraggingElement = false;
//     }
//   }

//   void _handleEditModeMove(PointerMoveEvent event) {
//     if (_selectedElement == null && _selectedShape == null) return;

//     setState(() {
//       if (_isResizingMovableElement) {
//         _resizeElement(_selectedElement!, event);
//         return;
//       }

//       if (_isRotatingMovableElement) {
//         _rotateElement(_selectedElement!, event);
//         return;
//       }

//       if (_isResizingShape) {
//         _resizeShape(_selectedShape!.shape!, event);
//         return;
//       }

//       if (_isRotatingShape) {
//         _rotateShape(_selectedShape!.shape!, event);
//         return;
//       }

//       if (_isDraggingElement) {
//         _selectedElement!.position +=
//             event.localDelta *
//             (1 / transformationController.value.getMaxScaleOnAxis());
//       }

//       if (_isDraggingShape) {
//         _selectedShape!.shape!.shapeStartPoint +=
//             event.localDelta *
//             (1 / transformationController.value.getMaxScaleOnAxis());

//         _selectedShape!.shape!.shapeEndPoint +=
//             event.localDelta *
//             (1 / transformationController.value.getMaxScaleOnAxis());
//       }
//     });
//   }

//   void _handleEditModeUp(PointerUpEvent event) {
//     setState(() {
//       if (_isDeletingMovableElement && _selectedElement != null) {
//         _deleteElement(_selectedElement!);
//       } else if (_isDeletingShape && _selectedShape != null) {
//         _deleteShape(_selectedShape!);
//       }

//       _isResizingMovableElement = false;
//       _isDeletingMovableElement = false;
//       _isDeletingShape = false;
//       _isResizingShape = false;
//       _isRotatingShape = false;
//       _isRotatingMovableElement = false;
//       _isDraggingElement = false;
//       _isDraggingShape = false;
//     });
//   }

//   void _deleteElement(MovableElement element) async {
//     setState(() {
//       _images.remove(element);
//       _elements.removeWhere(
//         (thisElement) =>
//             thisElement.movableElement != null &&
//             thisElement.movableElement!.id == element.id,
//       );
//       _selectedElement = null;
//     });
//     if (await File(element.filePath!).exists()) {
//       await File(element.filePath!).delete();
//     }
//   }

//   void _deleteShape(CanvasElement shape) {
//     setState(() {
//       _elements.remove(shape);
//       _selectedShape = null;
//     });
//   }

//   void _resizeElement(MovableElement element, PointerMoveEvent event) {
//     setState(() {
//       final Offset touchPoint = _toLocal(event.localPosition);

//       final double dx = touchPoint.dx - _resizeAnchor.dx;
//       final double dy = touchPoint.dy - _resizeAnchor.dy;

//       final double cosTheta = Math.cos(element.rotation);
//       final double sinTheta = Math.sin(element.rotation);

//       double newWidth = (dx * cosTheta) + (dy * sinTheta);

//       if (newWidth < 50) newWidth = 50;
//       if (newWidth > 500) newWidth = 500;

//       element.width = newWidth;
//       element.height = newWidth / element.aspectRatio!;

//       final double centerX = newWidth / 2;
//       final double centerY = element.height / 2;

//       final double rotatedCenterX = centerX * cosTheta - centerY * sinTheta;
//       final double rotatedCenterY = centerX * sinTheta + centerY * cosTheta;

//       final Offset newCenter =
//           _resizeAnchor + Offset(rotatedCenterX, rotatedCenterY);

//       element.position = Offset(
//         newCenter.dx - newWidth / 2,
//         newCenter.dy - element.height / 2,
//       );
//     });
//   }

//   void _resizeShape(HiveShape shape, PointerMoveEvent event) {
//     setState(() {
//       final Offset touchPoint = _toLocal(event.localPosition);

//       final double dx = touchPoint.dx - shape.shapeStartPoint.dx;
//       final double dy = touchPoint.dy - shape.shapeStartPoint.dy;

//       final double cosTheta = Math.cos(shape.rotation);
//       final double sinTheta = Math.sin(shape.rotation);

//       double newWidth = (dx * cosTheta) + (dy * sinTheta);

//       if (dx > 50 && dy > 50) {
//         shape.shapeEndPoint = touchPoint - Offset(20, 20);
//       }
//     });
//   }

//   void _runSnapAnimation(Offset targetPosition) {
//     _dockAnimation = Tween<Offset>(
//       begin: Offset(toolbarX, toolbarY),
//       end: targetPosition,
//     ).animate(_dockController);

//     _dockController.reset();
//     _dockController.forward();
//   }

//   Size getSize() {
//     final RenderBox? renderBox =
//         _toolbarKey.currentContext?.findRenderObject() as RenderBox?;
//     if (renderBox != null) {
//       final Size size = renderBox.size;
//       // final Offset position = renderBox.localToGlobal(Offset.zero);

//       return size;
//     }
//     return Size(0, 0);
//   }

//   // void _resizeElement(MovableElement element, PointerMoveEvent event) {
//   //   setState(() {
//   //     final Offset center = Offset(
//   //       element.position.dx + element.width / 2,
//   //       element.position.dy + element.height / 2,
//   //     );

//   //     final currentDistanceToCenter =
//   //         (_toLocal(event.localPosition) - _initialCenter).distance;

//   //     final newScale = currentDistanceToCenter / _initialDistanceToCenter;

//   //     double newWidth = _initialWidth * newScale;

//   //     // final deltaY = (d1 > d2) ? dy : -dy;

//   //     // final deltaX = dx;
//   //     // final deltaY = dy;

//   //     if (newWidth < 50) newWidth = 50;
//   //     if (newWidth > 500) newWidth = 500;
//   //     element.width = newWidth;
//   //     element.height = newWidth / element.aspectRatio!;
//   //   });
//   // }

//   // void _resizeElement(MovableElement element, PointerMoveEvent event) {
//   //   setState(() {
//   //     // final Offset center = Offset(
//   //     //   element.position.dx + element.width / 2,
//   //     //   element.position.dy + element.height / 2,
//   //     // );

//   //     final d1 = (_initialPoint - _initialCenter).distance;
//   //     final d2 = (_toLocal(event.localPosition) - _initialCenter).distance;

//   //     final dx = (_toLocal(event.localPosition).dx - _initialPoint.dx);
//   //     // final dy = (event.localPosition.dy - _initialPoint.dy);

//   //     final deltaX = (d2 > d1) ? dx : -dx;
//   //     // final deltaY = (d1 > d2) ? dy : -dy;

//   //     // final deltaX = dx;
//   //     // final deltaY = dy;

//   //     double newWidth = (dx > 0) ? _initialWidth + deltaX : _initialWidth - deltaX;
//   //     if (newWidth < 50) newWidth = 50;
//   //     if (newWidth > 500) newWidth = 500;
//   //     element.width = newWidth;
//   //     element.height = newWidth / element.aspectRatio!;
//   //   });
//   // }

//   // void _resizeElement(MovableElement element, PointerMoveEvent event) {
//   //   setState(() {
//   //     final double currentScale = transformationController.value
//   //         .getMaxScaleOnAxis();

//   //     final double dx = event.delta.dx / currentScale;
//   //     final double dy = event.delta.dy / currentScale;

//   //     final double cosTheta = Math.cos(element.rotation);
//   //     final double sinTheta = Math.sin(element.rotation);

//   //     final double projectedDelta = (dx * cosTheta) + (dy * sinTheta);

//   //     double newWidth = element.width + projectedDelta;

//   //     if (newWidth < 50) newWidth = 50;
//   //     if (newWidth > 500) newWidth = 500;

//   //     element.width = newWidth;
//   //     element.height = newWidth / element.aspectRatio!;
//   //   });
//   // }

//   void _rotateElement(MovableElement element, PointerMoveEvent event) {
//     setState(() {
//       final currentTouchAngle = Math.atan2(
//         _toLocal(event.localPosition).dy - _initialCenter.dy,
//         _toLocal(event.localPosition).dx - _initialCenter.dx,
//       );

//       final angleDelta = currentTouchAngle - _initialTouchAngle;

//       element.rotation = _initialRotation + angleDelta;

//       if (element.rotation.abs() * 180 / Math.pi < 5) {
//         element.rotation = 0;
//       }
//     });
//   }

//   void _rotateShape(HiveShape shape, PointerMoveEvent event) {
//     setState(() {
//       final currentTouchAngle = Math.atan2(
//         _toLocal(event.localPosition).dy - _initialCenter.dy,
//         _toLocal(event.localPosition).dx - _initialCenter.dx,
//       );

//       final angleDelta = currentTouchAngle - _initialTouchAngle;

//       shape.rotation = _initialRotation + angleDelta;

//       if (shape.rotation.abs() * 180 / Math.pi < 5) {
//         shape.rotation = 0;
//       }
//     });
//   }

//   MovableElement _createMovableElementFromData(MovableElementData data) {
//     late final Widget widget;

//     if (data.type == ElementType.image) {
//       widget = _buildImageWidget(
//         data.filePath,
//         data.id,
//         data.width,
//         data.height,
//       );
//     } else if (data.type == ElementType.document) {
//       widget = _buildDocumentWidget(
//         data.filePath,
//         data.title ?? "Document",
//         data.id,
//         data.width,
//         data.height,
//       );
//     }

//     return MovableElement.fromData(data, widget);
//   }
// }

// class BackgroundPainter extends CustomPainter {
//   final double boundaryMarginWidth;
//   final double boundaryMarginHeight;
//   final Rect viewport;
//   BackgroundPainter(
//     this.boundaryMarginWidth,
//     this.boundaryMarginHeight,
//     this.viewport,
//   );

//   final gridPaint = Paint()
//     ..color = const Color.fromARGB(255, 136, 136, 136)
//     ..strokeWidth = 1.0;

//   static final double gridSize = 50.0;

//   @override
//   void paint(Canvas canvas, Size size) {
//     for (
//       double x = -boundaryMarginWidth;
//       x < size.width + boundaryMarginWidth;
//       x += gridSize
//     ) {
//       //   if (viewport.overlaps(Rect.fromPoints())) {

//       // }
//       canvas.drawLine(
//         Offset(x, -boundaryMarginHeight),
//         Offset(x, size.height + boundaryMarginHeight),
//         gridPaint,
//       );
//     }

//     for (
//       double y = -boundaryMarginHeight;
//       y < size.height + boundaryMarginHeight;
//       y += gridSize
//     ) {
//       canvas.drawLine(
//         Offset(-boundaryMarginWidth, y),
//         Offset(size.width + boundaryMarginWidth, y),
//         gridPaint,
//       );
//     }

//     // for (
//     //   double y = -boundaryMarginHeight;
//     //   y < size.height + boundaryMarginHeight;
//     //   y += 50
//     // ) {
//     //   canvas.drawLine(
//     //     Offset(-boundaryMarginWidth, y),
//     //     Offset(size.width + boundaryMarginWidth, y),
//     //     gridPaint,
//     //   );
//     // }

//     // for (
//     //   double x = -boundaryMarginWidth;
//     //   x < size.width + boundaryMarginWidth;
//     //   x += 50
//     // ) {
//     //   for (
//     //     double y = -boundaryMarginHeight;
//     //     y < size.height + boundaryMarginHeight;
//     //     y += 50
//     //   ) {
//     //     canvas.drawCircle(Offset(x, y), 2, gridPaint);
//     //   }
//     // }
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return false;
//   }
// }

// class DrawingPainter extends CustomPainter {
//   final List<CanvasAction> actions;
//   final Rect viewport;
//   final Offset? eraserPoint;
//   final bool isEraserMode;
//   final Offset? shapeStartPoint;
//   final Offset? shapeEndPoint;
//   final ShapeType? shape;
//   final Color currentColor;
//   final List<CanvasElement> elements;
//   final CanvasElement? _selectedShape;

//   DrawingPainter(
//     this.actions,
//     this.viewport,
//     this.eraserPoint,
//     this.isEraserMode,
//     this.shapeStartPoint,
//     this.shapeEndPoint,
//     this.shape,
//     this.currentColor,
//     this.elements,
//     this._selectedShape,
//   );

//   static final Paint _eraserFillPaint = Paint()
//     ..color = Colors.black.withValues(alpha: 0.1)
//     ..style = PaintingStyle.fill;

//   static final Paint _eraserBorderPaint = Paint()
//     ..color = Colors.black.withValues(alpha: 0.3)
//     ..style = PaintingStyle.stroke
//     ..strokeWidth = 1.0;

//   static final Paint _testPaint = Paint()
//     ..color = Colors.blue
//     ..style = PaintingStyle.fill;

//   static final eraserSize = 40.0;

//   @override
//   void paint(Canvas canvas, Size size) {
//     if (shape != null && shapeStartPoint != null && shapeEndPoint != null) {
//       if (shape == ShapeType.rectangle) {
//         canvas.drawRect(
//           Rect.fromPoints(shapeStartPoint!, shapeEndPoint!),
//           _testPaint..color = currentColor,
//         );
//       } else if (shape == ShapeType.circle) {
//         canvas.drawCircle(
//           Offset(
//             (shapeStartPoint!.dx + shapeEndPoint!.dx) / 2,
//             (shapeStartPoint!.dy + shapeEndPoint!.dy) / 2,
//           ),
//           (shapeEndPoint! - shapeStartPoint!).distance / 2,
//           _testPaint..color = currentColor,
//         );
//       }
//     }

//     if (isEraserMode && eraserPoint != null) {
//       canvas.drawCircle(eraserPoint!, eraserSize / 2, _eraserFillPaint);
//       canvas.drawCircle(eraserPoint!, eraserSize / 2, _eraserBorderPaint);
//     }
//   }

//   @override
//   bool shouldRepaint(covariant DrawingPainter oldDelegate) {
//     // return oldDelegate.strokes != strokes;
//     return true;
//   }
// }

// class ElementsPainter extends CustomPainter {
//   final List<CanvasElement> elements;
//   final Rect viewport;

//   ElementsPainter({required this.elements, required this.viewport});

//   @override
//   void paint(Canvas canvas, Size size) {
//     for (final element in elements) {
//       final HiveStroke stroke = element.stroke!;
//       if (viewport.overlaps(
//         Rect.fromPoints(stroke.bounds.topLeft, stroke.bounds.bottomRight),
//       )) {
//         canvas.drawPath(stroke.path, stroke.paint);
//         // canvas.drawRect(
//         //   stroke.bounds,
//         //   Paint()
//         //     ..style = PaintingStyle.stroke
//         //     ..color = Colors.red,
//         // );
//       }
//       // canvas.drawPath(stroke.path, stroke.paint);
//     }
//   }

//   @override
//   bool shouldRepaint(covariant ElementsPainter oldDelegate) {
//     return oldDelegate.elements != elements;
//   }
// }
