import 'dart:io';
import 'dart:math' as Math;
import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:studyfold/Utils/drawing_controller.dart';
import 'package:studyfold/canvas_action.dart';
import 'package:studyfold/edit_image_page.dart';
import 'package:studyfold/models/canvas_element.dart';
import 'package:studyfold/models/element_type.dart';
import 'package:studyfold/models/hive_shape.dart';
import 'package:studyfold/models/hive_stroke.dart';
import 'package:studyfold/models/movable_element.dart';
import 'package:studyfold/models/shape_type.dart';
import 'package:studyfold/overlays/border_settings_popup.dart';
import 'package:studyfold/overlays/crop_overlay.dart';
import 'package:studyfold/overlays/link_menu_popup.dart';
import 'package:studyfold/overlays/pen_settings_button.dart';
import 'package:studyfold/overlays/shape_menu_popup.dart';
import 'package:studyfold/services/folder_service.dart';
import 'package:studyfold/widgets/element_options_widgets.dart';
import 'package:studyfold/widgets/canvas_toolbar.dart';
import 'package:studyfold/widgets/color_circle.dart';

class DrawingBoardWidget extends StatefulWidget {
  final DrawingController drawingController;
  final Size canvasSize;
  final void Function(Rect viewport) onAddImageRequested;
  final void Function(Rect viewport) onAddDocumentRequested;
  final void Function({required CanvasElement element})? onEditImageRequested;
  final Widget? background;
  final bool showCropOverlay;
  final Rect? initialCropRect;
  final ValueChanged<Rect>? onCropChanged;
  final bool isExporting;

  const DrawingBoardWidget({
    super.key,
    required this.drawingController,
    required this.canvasSize,
    required this.onAddImageRequested,
    required this.onAddDocumentRequested,
    this.onEditImageRequested,
    this.background,
    this.showCropOverlay = false,
    this.initialCropRect,
    this.onCropChanged,
    this.isExporting = false,
  });

  @override
  State<DrawingBoardWidget> createState() => _DrawingBoardWidgetState();
}

class _DrawingBoardWidgetState extends State<DrawingBoardWidget> {
  late DrawingController drawingController;
  final ElementOptionsWidgets elementOptionsWidgets = ElementOptionsWidgets();

  @override
  void initState() {
    super.initState();
    drawingController = widget.drawingController;
    widget.drawingController.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() => setState(() {});

  @override
  void dispose() {
    widget.drawingController.removeListener(_onControllerUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Portal(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = drawingController.calculateViewport(
            constraints.biggest,
          );

          if (widget.isExporting) {
            return _buildContent(viewport);
          }

          return Stack(
            children: [
              Positioned.fill(
                child: Listener(
                  onPointerDown: _onPointerDown,
                  onPointerMove: _onPointerMove,
                  onPointerUp: _onPointerUp,
                  onPointerCancel: _onPointerCancel,
                  child: InteractiveViewer(
                    transformationController:
                        drawingController.transformationController,
                    panEnabled:
                        drawingController.isPanMode ||
                        drawingController.isTwoFingersDown,
                    scaleEnabled: true,
                    minScale: drawingController.config.minZoom,
                    maxScale: drawingController.config.maxZoom,
                    onInteractionEnd: (details) {
                      setState(() {
                        drawingController.currentScale = drawingController
                            .transformationController
                            .value
                            .getMaxScaleOnAxis();
                      });
                    },
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    child: _buildContent(viewport),
                  ),
                ),
              ),

              if (drawingController.config.enableElementOptions)
                Positioned(
                  bottom: 0,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 100),
                    transitionBuilder: (child, animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0.0, 1.0),
                          end: Offset(0, 0),
                        ).animate(animation),
                        child: child,
                      );
                    },
                    child:
                        (drawingController.selectedShape == null &&
                            drawingController.selectedElement == null)
                        ? SizedBox.shrink()
                        : Container(
                            key: ValueKey(
                              drawingController.selectedShape == null &&
                                  drawingController.selectedElement == null,
                            ),
                            color: Colors.transparent,
                            width: screenSize.width,
                            child: _buildElementOptions(),
                          ),
                  ),
                ),

              if (drawingController.config.showToolbar)
                CanvasToolbar(
                  drawingController: drawingController,
                  clampSize: screenSize,
                  onAddImageRequested: widget.onAddImageRequested,
                  onAddDocumentRequested: widget.onAddDocumentRequested,
                  viewport: viewport,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(Rect viewport) {
    return SizedBox(
      width: widget.canvasSize.width,
      height: widget.canvasSize.height,
      child: ClipRRect(
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: CustomPaint(
                painter: BackgroundPainter(1000, 1000, viewport),
              ),
            ),
            if (widget.background != null)
              Positioned.fill(child: widget.background!),

            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: drawingController.transformationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: DrawingPainter(
                        drawingController.actions,
                        viewport,
                        drawingController.eraserPoint,
                        drawingController.currentDrawMode ==
                            CanvasDrawMode.eraser,
                        drawingController.shapeStartPoint,
                        drawingController.shapeEndPoint,
                        drawingController.currentShape,
                        drawingController.selectedColor,
                        drawingController.elements,
                        drawingController.selectedShape,
                      ),
                    );
                  },
                ),
              ),
            ),

            SizedBox(
              // width: double.infinity,
              // height: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ...drawingController.documents.map((element) {
                    final isSelected =
                        drawingController.selectedElement == element;
                    final showControls =
                        isSelected && !drawingController.isDraggingElement;

                    return Positioned(
                      left: element.position.dx,
                      top: element.position.dy,
                      child: Transform.rotate(
                        angle: element.rotation,
                        alignment: Alignment.center,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: element.width,
                              height: element.height,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blueAccent
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: element.widget,
                            ),

                            Positioned(
                              top: -15,
                              right: -15,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: showControls ? 1.0 : 0.0,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 4,
                                        color: Colors.black26,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            Positioned(
                              bottom: -15,
                              right: -15,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: showControls ? 1.0 : 0.0,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.blueAccent,
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        blurRadius: 4,
                                        color: Colors.black26,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.open_in_full,
                                    size: 18,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ),
                            ),

                            Positioned(
                              bottom: -15,
                              left: -15,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: showControls ? 1.0 : 0.0,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.blueAccent,
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        blurRadius: 4,
                                        color: Colors.black26,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.rotate_left,
                                    size: 18,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  ..._buildCanvasLayers(viewport, drawingController.elements),

                  if (widget.showCropOverlay && widget.initialCropRect != null)
                    AnimatedBuilder(
                      animation: drawingController.transformationController,
                      builder: (context, child) {
                        final double currentScale = drawingController
                            .transformationController
                            .value
                            .getMaxScaleOnAxis();
                        final double inverseScale = 1 / currentScale;

                        return IgnorePointer(
                          ignoring: drawingController.isTwoFingersDown,
                          child: CropOverlay(
                            imageSize: widget.canvasSize,
                            initialCropRect: widget.initialCropRect!,
                            inverseScale: inverseScale,
                            onCropChanged: widget.onCropChanged!,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    ;
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!drawingController.config.enabled) return;
    setState(() {
      drawingController.previousPointersCount =
          drawingController.pointersCount++;
      drawingController.updateTwoFingerStatus();

      if ((drawingController.isPanMode || drawingController.isTwoFingersDown)) {
        drawingController.abortStroke();
        return;
      }

      final point = drawingController.toLocal(event.localPosition);

      if (drawingController.canvasMode == CanvasMode.edit) {
        drawingController.handleEditModeDown(point);
      } else {
        drawingController.handleDrawModeDown(point);
      }
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!drawingController.config.enabled) return;
    if (drawingController.isPanMode || drawingController.isTwoFingersDown) {
      return;
    }

    if (drawingController.canvasMode == CanvasMode.edit) {
      drawingController.handleEditModeMove(event);
    } else {
      drawingController.handleDrawModeMove(event);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!drawingController.config.enabled) return;
    setState(() {
      drawingController.previousPointersCount =
          drawingController.pointersCount--;
      drawingController.updateTwoFingerStatus();

      if (drawingController.canvasMode == CanvasMode.edit) {
        drawingController.handleEditModeUp(event);
      } else {
        drawingController.handleDrawModeUp(event);
      }
    });
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (!drawingController.config.enabled) return;
    setState(() {
      drawingController.previousPointersCount = drawingController.pointersCount;
      drawingController.pointersCount = 0;
      drawingController.updateTwoFingerStatus();
      if (drawingController.isPanMode || drawingController.isTwoFingersDown)
        return;
      drawingController.isDrawing = false;
      drawingController.finishDrawing(event.localPosition);
    });
  }

  List<Widget> _buildCanvasLayers(Rect viewport, List<CanvasElement> elements) {
    List<Widget> layers = [];
    List<CanvasElement> strokeBuffer = [];

    for (int i = 0; i < elements.length; i++) {
      final element = elements[i];

      if (element.stroke != null) {
        // It's a stroke! Don't draw yet, just add to buffer.
        strokeBuffer.add(element);
      } else {
        // It's a Widget (Shape or Image)!

        // 1. FLUSH: If we have pending strokes below this shape, draw them now.
        if (strokeBuffer.isNotEmpty) {
          layers.add(
            // RepaintBoundary is crucial here for performance!
            RepaintBoundary(
              child: CustomPaint(
                size: Size.infinite,
                // Create a painter for ONLY these specific strokes
                painter: ElementsPainter(
                  elements: List.from(strokeBuffer),
                  viewport: viewport,
                ),
              ),
            ),
          );
          strokeBuffer.clear(); // Reset buffer
        }

        // 2. DRAW WIDGET: Add the shape/image on top of the strokes
        if (element.shape != null) {
          layers.add(_buildShape(element));
        } else if (element.movableElement != null) {
          if (element.movableElement!.type == ElementType.image) {
            layers.add(
              _buildImage(
                drawingController.images.firstWhere(
                  (image) => image.id == element.movableElement!.id,
                ),
                element.children,
              ),
            );
          }
        }
      }
    }

    // 3. FINAL FLUSH: Draw any remaining strokes on top of the last shape
    if (strokeBuffer.isNotEmpty) {
      layers.add(
        RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: ElementsPainter(
              elements: strokeBuffer,
              viewport: viewport,
            ),
          ),
        ),
      );
    }

    return layers;
  }

  Widget _buildShape(CanvasElement element) {
    final HiveShape shape = element.shape!;
    final rect = Rect.fromPoints(shape.shapeStartPoint, shape.shapeEndPoint);
    final bool isSelected = (drawingController.selectedShape == element);
    final showControls = isSelected && !drawingController.isDraggingShape;
    final double degrees = (shape.rotation * 180 / Math.pi);
    final double normalizedDegrees = (degrees % 360 + 360) % 360;

    switch (shape.type) {
      case ShapeType.rectangle:
        return _buildRectangle(
          shape,
          rect,
          isSelected,
          showControls,
          normalizedDegrees,
        );
      case ShapeType.circle:
        return _buildCircle(shape, rect, isSelected, showControls);
      case ShapeType.triangle:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ShapeType.line:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  Widget _buildImage(MovableElement element, List<CanvasElement>? children) {
    final isSelected = drawingController.selectedElement == element;
    final showControls = isSelected && !drawingController.isDraggingElement;
    final double degrees = (element.rotation * 180 / Math.pi);
    final double normalizedDegrees = (degrees % 360 + 360) % 360;
    final Offset center = Offset(
      element.position.dx + element.width,
      element.position.dy + element.height,
    );

    final cropRect = Rect.fromPoints(
      element.cropRectStart,
      element.cropRectEnd,
    );

    return Positioned(
      left: element.position.dx,
      top: element.position.dy,
      child: Transform.rotate(
        angle: element.rotation,
        alignment: Alignment.center,
        child: SizedBox(
          width: element.width,
          height: element.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ClipRect(
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: SizedBox(
                      width: cropRect.width,
                      height: cropRect.height,
                      // 2. We clip the overflowing parts of the original image
                      child: ClipRect(
                        child: Stack(
                          children: [
                            // 3. Shift the original image back by the crop's left/top offsets
                            Positioned(
                              left: -cropRect.left,
                              top: -cropRect.top,
                              child: SizedBox(
                                width: element.originalWidth,
                                height: element.originalHeight,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    SizedBox(
                                      width: element.originalWidth,
                                      height: element.originalHeight,
                                      child: element.widget,
                                    ),
                                    ..._buildCanvasLayers(
                                      Rect.fromLTWH(
                                        0,
                                        0,
                                        element.originalWidth,
                                        element.originalHeight,
                                      ),
                                      children ?? [],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (isSelected && drawingController.isRotatingMovableElement)
                Positioned(
                  top: element.height / 2,
                  left: element.width / 2,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -0.5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: const Color.fromARGB(150, 0, 0, 0),
                      ),
                      child: Text(
                        "${normalizedDegrees.toStringAsFixed(1)}°",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),

              // Delete Button
              // Delete Button
              // Delete Button
              // Delete Button
              Positioned(
                top: -15,
                right: -15,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: showControls ? 1.0 : 0.0,
                  child: Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(blurRadius: 4, color: Colors.black26),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: -15,
                right: -15,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: showControls ? 1.0 : 0.0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blueAccent, width: 2),
                      boxShadow: const [
                        BoxShadow(blurRadius: 4, color: Colors.black26),
                      ],
                    ),
                    child: const Icon(
                      Icons.open_in_full,
                      size: 18,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: -15,
                left: -15,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: showControls ? 1.0 : 0.0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blueAccent, width: 2),
                      boxShadow: const [
                        BoxShadow(blurRadius: 4, color: Colors.black26),
                      ],
                    ),
                    child: const Icon(
                      Icons.rotate_left,
                      size: 18,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildRectangle(
    HiveShape shape,
    Rect rect,
    bool isSelected,
    bool showControls,
    double rotation,
  ) {
    final bool isLocked = shape.config.isLocked;

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: Transform.rotate(
        angle: shape.rotation,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: (shape.config.fill) ? Color(shape.colorValue) : null,
                border: Border.all(
                  color: isSelected ? Colors.blueAccent : Colors.lightGreen,
                  width: shape.config.borderWidth,
                  style: (shape.config.borderWidth == 0.0)
                      ? BorderStyle.none
                      : BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(shape.config.borderRadius),
                shape: BoxShape.rectangle,
              ),
            ),

            // Delete Button
            if (!isLocked)
              Positioned(
                top: -40 / drawingController.currentScale,
                right: -40 / drawingController.currentScale,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: showControls ? 1.0 : 0.0,
                  child: Container(
                    width: 40 / drawingController.currentScale,
                    height: 40 / drawingController.currentScale,
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(blurRadius: 4, color: Colors.black26),
                      ],
                    ),
                    child: Icon(
                      Icons.close,
                      size: (drawingController.currentScale > 2)
                          ? 5
                          : 20 / drawingController.currentScale,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Resize Button
            if (!isLocked)
              Positioned(
                bottom: -40 / drawingController.currentScale,
                right: -40 / drawingController.currentScale,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: showControls ? 1.0 : 0.0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blueAccent, width: 2),
                      boxShadow: const [
                        BoxShadow(blurRadius: 4, color: Colors.black26),
                      ],
                    ),
                    child: const Icon(
                      Icons.open_in_full,
                      size: 18,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ),

            // Rotate Button
            if (!isLocked)
              Positioned(
                bottom: -40 / drawingController.currentScale,
                left: -40 / drawingController.currentScale,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: showControls ? 1.0 : 0.0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blueAccent, width: 2),
                      boxShadow: const [
                        BoxShadow(blurRadius: 4, color: Colors.black26),
                      ],
                    ),
                    child: const Icon(
                      Icons.rotate_left,
                      size: 18,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircle(
    HiveShape shape,
    Rect rect,
    bool isSelected,
    bool showControls,
  ) {
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Color(shape.colorValue),
              border: Border.all(
                color: isSelected ? Colors.blueAccent : Colors.transparent,
                width: shape.config.borderWidth,
              ),
              shape: BoxShape.circle,
            ),
          ),

          Positioned(
            top: -40 / drawingController.currentScale,
            right: -40 / drawingController.currentScale,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: showControls ? 1.0 : 0.0,
              child: Container(
                width: 40 / drawingController.currentScale,
                height: 40 / drawingController.currentScale,
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
                ),
                child: Icon(
                  Icons.close,
                  size: (drawingController.currentScale > 2)
                      ? 5
                      : 20 / drawingController.currentScale,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElementOptions() {
    return ClipRRect(
      borderRadius: BorderRadiusGeometry.vertical(top: Radius.circular(10)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.white.withValues(alpha: 0.75),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (drawingController.selectedShape != null)
                elementOptionsWidgets.buildElementOption(
                  "Background Image",
                  Icons.image_outlined,
                  () {},
                ),

              // _buildElementOption("Fill Color", MyCustomIcons.paintcan, () {}),
              if (drawingController.selectedShape != null)
                BorderSettingsPopup(
                  key: ValueKey(drawingController.selectedShape.hashCode),
                  shape: drawingController.selectedShape!.shape!,
                  onConfigChanged: (newConfig) {
                    setState(() {
                      drawingController.selectedShape!.shape!.config =
                          newConfig;
                    });
                  },
                  onDimensionsChanged: (newDimensions) {
                    final currentShape =
                        drawingController.selectedShape!.shape!;

                    setState(() {
                      final start = currentShape.shapeStartPoint;
                      final end = currentShape.shapeEndPoint;

                      final double safeWidth = newDimensions.width.clamp(
                        50.0,
                        1000.0,
                      );
                      final double safeHeight = newDimensions.height.clamp(
                        50.0,
                        1000.0,
                      );

                      final double signX = (end.dx >= start.dx) ? 1.0 : -1.0;
                      final double signY = (end.dy >= start.dy) ? 1.0 : -1.0;

                      currentShape.shapeEndPoint = Offset(
                        start.dx + (safeWidth * signX),
                        start.dy + (safeHeight * signY),
                      );
                    });
                  },
                  onColorChanged: (color) => setState(
                    () => drawingController.selectedShape!.shape!.colorValue =
                        color.toARGB32(),
                  ),
                ),

              if (drawingController.selectedShape != null)
                elementOptionsWidgets.buildElementOption(
                  "Edit Shape",
                  Icons.access_alarm,
                  () {},
                ),

              if (drawingController.selectedElement != null &&
                  drawingController.selectedElement!.type == ElementType.image)
                elementOptionsWidgets.buildElementOption(
                  "Edit Image",
                  Icons.access_alarm,
                  () {
                    widget.onEditImageRequested!(
                      element: drawingController.elements.firstWhere(
                        (element) =>
                            element.movableElement != null &&
                            element.movableElement!.id ==
                                drawingController.selectedElement!.id,
                      ),
                    );
                  },
                ),

              // _buildElementOption(
              //   "Border Settings",
              //   MyCustomIcons.paintcan,
              //   () {},
              // ),
              // _buildElementOption("Size", Icons.change_circle, () {}),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildElementOption(
  //   String text,
  //   IconData icon,
  //   VoidCallback onPressed,
  // ) {
  //   return Column(
  //     children: [
  //       Text(text, style: TextStyle(color: Colors.black)),
  //       _buildIconBtn(icon, true, false, onPressed),
  //     ],
  //   );
  // }

  // Widget _buildElementOptionWithPopup(
  //   String text,
  //   dynamic popup,
  //   VoidCallback onPressed,
  // ) {
  //   return Column(
  //     children: [
  //       Text(text, style: TextStyle(color: Colors.black)),
  //       popup,
  //     ],
  //   );
  // }

  Widget _buildToolBar(Rect viewport, Size screenSize) {
    return ClipRRect(
      borderRadius: (drawingController.capsuleToolbar)
          ? BorderRadius.circular(50)
          : BorderRadius.circular(0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 40,
          width: (drawingController.capsuleToolbar) ? null : screenSize.width,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: (drawingController.capsuleToolbar)
                ? BorderRadius.circular(50)
                : null,
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              // mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanUpdate: (details) {
                    setState(() {
                      drawingController.toolbarX += details.delta.dx;
                      drawingController.toolbarY += details.delta.dy;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.only(right: 12, left: 4),
                    height: double.infinity,
                    child: const Icon(
                      Icons.drag_indicator_rounded,
                      color: Colors.grey,
                      size: 24,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 8,
                  ),
                  child: VerticalDivider(
                    width: 1,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),

                _buildIconBtn(
                  Icons.undo_rounded,
                  drawingController.actions.isNotEmpty,
                  false,
                  () {
                    setState(() {
                      final lastAction = drawingController.actions.removeLast();
                      drawingController.undoActions.add(lastAction);
                      if (lastAction.type == ActionType.draw) {
                        for (var record in lastAction.strokes) {
                          // drawingController.strokes.remove(record.stroke);
                          drawingController.elements.removeWhere((element) {
                            return element.stroke != null &&
                                element.stroke!.id == record.stroke.id;
                          });
                        }
                      } else if (lastAction.type == ActionType.erase) {
                        // for (var record in lastAction.strokes) {
                        //   if (record.index <=
                        //       drawingController.strokes.length) {
                        //     // drawingController.strokes.insert(record.index, record.stroke);
                        //     drawingController.elements.insert(
                        //       record.index,
                        //       CanvasElement(stroke: record.stroke),
                        //     );
                        //   } else {
                        //     drawingController.elements.add(
                        //       CanvasElement(stroke: record.stroke),
                        //     );
                        //     // drawingController.strokes.add(record.stroke);
                        //   }
                        // }
                      } else if (lastAction.type == ActionType.addElement) {
                        for (var record in lastAction.shapes) {
                          drawingController.elements.removeWhere((element) {
                            if (drawingController.selectedShape!.shape!.id ==
                                element.shape!.id)
                              drawingController.selectedShape = null;
                            return element.shape != null &&
                                element.shape!.id == record.shape.id;
                          });
                        }
                      }
                    });
                  },
                ),

                _buildIconBtn(
                  Icons.redo_rounded,
                  drawingController.undoActions.isNotEmpty,
                  false,
                  () {
                    setState(() {
                      final action = drawingController.undoActions.removeLast();
                      drawingController.actions.add(action);
                      if (action.type == ActionType.draw) {
                        for (var record in action.strokes) {
                          // drawingController.strokes.add(record.stroke);
                          drawingController.elements.add(
                            CanvasElement(stroke: record.stroke),
                          );
                        }
                      } else if (action.type == ActionType.erase) {
                        for (var record in action.strokes) {
                          // drawingController.strokes.remove(record.stroke);
                          drawingController.elements.removeWhere((element) {
                            return element.stroke != null &&
                                element.stroke!.id == record.stroke.id;
                          });
                        }
                      } else if (action.type == ActionType.addElement) {
                        for (var record in action.shapes) {
                          drawingController.elements.insert(
                            record.index,
                            CanvasElement(shape: record.shape),
                          );
                        }
                      }
                    });
                  },
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 8,
                  ),
                  child: VerticalDivider(
                    width: 1,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),

                PenSettingsButton(
                  key: drawingController.penButtonKey,
                  currentSize: drawingController.selectedSize,
                  currentColor: drawingController.selectedColor,
                  penButtonKey: drawingController.penButtonKey,
                  isSelected:
                      drawingController.currentDrawMode == CanvasDrawMode.brush,
                  setSelected: () {
                    setState(() {
                      drawingController.currentDrawMode = CanvasDrawMode.brush;
                    });
                  },
                  onSizeChanged: (newSize) {
                    setState(() => drawingController.selectedSize = newSize);
                  },
                  onColorChanged: (newColor) {
                    setState(() {
                      drawingController.selectedColor = newColor;
                      drawingController.currentDrawMode == CanvasDrawMode.brush;
                    });
                  },
                ),

                _buildIconBtn(
                  Icons.delete,
                  true,
                  drawingController.currentDrawMode == CanvasDrawMode.eraser,
                  () {
                    setState(() {
                      drawingController.currentDrawMode = CanvasDrawMode.eraser;
                    });
                  },
                ),

                // SizedBox(
                //   width: 120,
                //   child: Column(
                //     mainAxisAlignment: MainAxisAlignment.center,
                //     children: [
                //       // Text("${drawingController.selectedSize.toInt()} px", style: TextStyle(fontSize: 8, color: Colors.grey)),
                //       SliderTheme(
                //         data: SliderTheme.of(context).copyWith(
                //           trackHeight: 4.0,
                //           thumbShape: const RoundSliderThumbShape(
                //             enabledThumbRadius: 6.0,
                //           ),
                //           overlayShape: const RoundSliderOverlayShape(
                //             overlayRadius: 14.0,
                //           ),
                //           activeTrackColor: Colors.black87,
                //           inactiveTrackColor: Colors.grey,
                //           thumbColor: Colors.black87,
                //         ),
                //         child: Slider(
                //           value: drawingController.selectedSize,
                //           min: 1.0,
                //           max: 100.0,
                //           onChanged: (value) =>
                //               setState(() => drawingController.selectedSize = value),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                const SizedBox(width: 8),

                ColorCircle(
                  selectedColor: drawingController.selectedColor,
                  onTap: () {
                    ColorCircle.showColorPickerDialog(
                      selectedColor: drawingController.selectedColor,
                      context: context,
                      onColorChanged: (color) => setState(() {
                        drawingController.currentDrawMode ==
                            CanvasDrawMode.brush;
                        drawingController.selectedColor = color;
                      }),
                    );
                  },
                ),
                LinkMenuPopup(
                  key: drawingController.linkMenuKey,
                  addImage: () {
                    widget.onAddImageRequested(viewport);
                  },
                  addDocument: () {
                    widget.onAddDocumentRequested(viewport);
                  },
                  linkMenuKey: drawingController.linkMenuKey,
                ),

                ShapeMenuPopup(
                  key: drawingController.shapeButtonKey,
                  currentConfig: drawingController.currentShapeConfig,
                  isSelected:
                      drawingController.currentDrawMode == CanvasDrawMode.shape,
                  shapeToolKey: drawingController.shapeButtonKey,
                  setSelected: () {
                    setState(() {
                      drawingController.currentDrawMode = CanvasDrawMode.shape;
                    });
                  },
                  onConfigChanged: (newConfig) {
                    setState(() {
                      drawingController.currentShapeConfig = newConfig;
                      drawingController.currentShape = newConfig.shapeType;
                      // switch (drawingController.currentShapeConfig.shapeTypeEnum) {
                      //   case ShapeTypeEnum.rectangle:
                      //     drawingController.currentShape = ShapeType.rectangle;
                      //     break;
                      //   case ShapeTypeEnum.circle:
                      //     drawingController.currentShape = ShapeType.circle;
                      //     break;
                      //   case ShapeTypeEnum.triangle:
                      //     drawingController.currentShape = ShapeType.rectangle;
                      //     break;
                      //   case ShapeTypeEnum.line:
                      //     drawingController.currentShape = ShapeType.rectangle;
                      //     break;
                      // }
                    });
                  },
                ),

                // ShapeMenuPopup(
                //   addRectangle: () {
                //     setState(() {
                //       drawingController.currentShape = ShapeType.rectangle;
                //     });
                //   },
                //   addCircle: () {
                //     setState(() {
                //       drawingController.currentShape = ShapeType.circle;
                //     });
                //   },
                // ),
                _buildIconBtn(
                  (drawingController.canvasMode == CanvasMode.edit)
                      ? Icons.back_hand
                      : Icons.draw_rounded,
                  true,
                  false,
                  () {
                    setState(() {
                      switch (drawingController.canvasMode) {
                        case CanvasMode.draw:
                          drawingController.canvasMode = CanvasMode.edit;
                          break;
                        case CanvasMode.edit:
                          drawingController.canvasMode = CanvasMode.draw;
                          break;
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconBtn(
    IconData icon,
    bool isEnabled,
    bool isSelected,
    VoidCallback onPressed,
  ) {
    return IconButton(
      icon: Icon(icon, size: 22),
      color: Colors.black87,
      isSelected: isSelected,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return Colors.black26;
          }
          return Colors.transparent;
        }),
      ),
      disabledColor: Colors.grey.withValues(alpha: 0.4),
      onPressed: isEnabled ? onPressed : null,
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      padding: EdgeInsets.zero,
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

  void _runSnapAnimation(Offset targetPosition) {
    drawingController.dockAnimation = Tween<Offset>(
      begin: Offset(drawingController.toolbarX, drawingController.toolbarY),
      end: targetPosition,
    ).animate(drawingController.dockController);

    drawingController.dockController.reset();
    drawingController.dockController.forward();
  }
}

class ElementsPainter extends CustomPainter {
  final List<CanvasElement> elements;
  final Rect viewport;

  ElementsPainter({required this.elements, required this.viewport});

  @override
  void paint(Canvas canvas, Size size) {
    for (final element in elements) {
      final HiveStroke stroke = element.stroke!;
      // if (viewport.overlaps(
      //   Rect.fromPoints(stroke.bounds.topLeft, stroke.bounds.bottomRight),
      // )) {
      canvas.drawPath(stroke.path, stroke.paint);
      // canvas.drawRect(
      //   stroke.bounds,
      //   Paint()
      //     ..style = PaintingStyle.stroke
      //     ..color = Colors.red,
      // );
      // }
      // canvas.drawPath(stroke.path, stroke.paint);
    }
  }

  @override
  bool shouldRepaint(covariant ElementsPainter oldDelegate) {
    return oldDelegate.elements != elements;
  }
}

class BackgroundPainter extends CustomPainter {
  final double boundaryMarginWidth;
  final double boundaryMarginHeight;
  final Rect viewport;
  BackgroundPainter(
    this.boundaryMarginWidth,
    this.boundaryMarginHeight,
    this.viewport,
  );

  final gridPaint = Paint()
    ..color = const Color.fromARGB(255, 136, 136, 136)
    ..strokeWidth = 1.0;

  static final double gridSize = 50.0;

  @override
  void paint(Canvas canvas, Size size) {
    for (
      double x = -boundaryMarginWidth;
      x < size.width + boundaryMarginWidth;
      x += gridSize
    ) {
      //   if (viewport.overlaps(Rect.fromPoints())) {

      // }
      canvas.drawLine(
        Offset(x, -boundaryMarginHeight),
        Offset(x, size.height + boundaryMarginHeight),
        gridPaint,
      );
    }

    for (
      double y = -boundaryMarginHeight;
      y < size.height + boundaryMarginHeight;
      y += gridSize
    ) {
      canvas.drawLine(
        Offset(-boundaryMarginWidth, y),
        Offset(size.width + boundaryMarginWidth, y),
        gridPaint,
      );
    }

    // for (
    //   double y = -boundaryMarginHeight;
    //   y < size.height + boundaryMarginHeight;
    //   y += 50
    // ) {
    //   canvas.drawLine(
    //     Offset(-boundaryMarginWidth, y),
    //     Offset(size.width + boundaryMarginWidth, y),
    //     gridPaint,
    //   );
    // }

    // for (
    //   double x = -boundaryMarginWidth;
    //   x < size.width + boundaryMarginWidth;
    //   x += 50
    // ) {
    //   for (
    //     double y = -boundaryMarginHeight;
    //     y < size.height + boundaryMarginHeight;
    //     y += 50
    //   ) {
    //     canvas.drawCircle(Offset(x, y), 2, gridPaint);
    //   }
    // }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class DrawingPainter extends CustomPainter {
  final List<CanvasAction> actions;
  final Rect viewport;
  final Offset? eraserPoint;
  final bool isEraserMode;
  final Offset? shapeStartPoint;
  final Offset? shapeEndPoint;
  final ShapeType? shape;
  final Color currentColor;
  final List<CanvasElement> elements;
  final CanvasElement? _selectedShape;

  DrawingPainter(
    this.actions,
    this.viewport,
    this.eraserPoint,
    this.isEraserMode,
    this.shapeStartPoint,
    this.shapeEndPoint,
    this.shape,
    this.currentColor,
    this.elements,
    this._selectedShape,
  );

  static final Paint _eraserFillPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.1)
    ..style = PaintingStyle.fill;

  static final Paint _eraserBorderPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  static final Paint _testPaint = Paint()
    ..color = Colors.blue
    ..style = PaintingStyle.fill;

  static final eraserSize = 40.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (shape != null && shapeStartPoint != null && shapeEndPoint != null) {
      if (shape == ShapeType.rectangle) {
        canvas.drawRect(
          Rect.fromPoints(shapeStartPoint!, shapeEndPoint!),
          _testPaint..color = currentColor,
        );
      } else if (shape == ShapeType.circle) {
        canvas.drawCircle(
          Offset(
            (shapeStartPoint!.dx + shapeEndPoint!.dx) / 2,
            (shapeStartPoint!.dy + shapeEndPoint!.dy) / 2,
          ),
          (shapeEndPoint! - shapeStartPoint!).distance / 2,
          _testPaint..color = currentColor,
        );
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
