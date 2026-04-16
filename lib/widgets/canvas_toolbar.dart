import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:studyfold/Utils/drawing_controller.dart';
import 'package:studyfold/canvas_action.dart';
import 'package:studyfold/models/canvas_element.dart';
import 'package:studyfold/overlays/link_menu_popup.dart';
import 'package:studyfold/overlays/pen_settings_button.dart';
import 'package:studyfold/overlays/shape_menu_popup.dart';
import 'package:studyfold/widgets/color_circle.dart';

class CanvasToolbar extends StatefulWidget {
  final DrawingController drawingController;
  final Size clampSize;
  final void Function(Rect viewport) onAddImageRequested;
  final void Function(Rect viewport) onAddDocumentRequested;
  final Rect viewport;

  const CanvasToolbar({
    super.key,
    required this.drawingController,
    required this.clampSize,
    required this.onAddImageRequested,
    required this.onAddDocumentRequested,
    required this.viewport,
  });

  @override
  State<CanvasToolbar> createState() => _CanvasToolbarState();
}

class _CanvasToolbarState extends State<CanvasToolbar> {
  late DrawingController drawingController;
  late Size clampSize;
  late Rect viewport;

  @override
  void initState() {
    super.initState();

    drawingController = widget.drawingController;
    clampSize = widget.clampSize;
    viewport = widget.viewport;
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;

    final Size toolbarSize = getSize();
    final double toolbarHeight = toolbarSize.height;
    final double toolbarWidth = toolbarSize.width;

    drawingController.toolbarX = drawingController.toolbarX.clamp(
      0,
      viewport.width - toolbarWidth,
    );
    drawingController.toolbarY = drawingController.toolbarY.clamp(
      0,
      viewport.height - toolbarHeight,
    );

    return Positioned(
      left: drawingController.toolbarX,
      top: drawingController.toolbarY,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            drawingController.toolbarX += details.delta.dx;
            drawingController.toolbarY += details.delta.dy;
          });
        },
        onPanEnd: (details) {
          const double snapThreshold = 30.0;

          double targetY = drawingController.toolbarY;
          double targetX = drawingController.toolbarX;

          if (drawingController.toolbarY < snapThreshold) {
            targetY = 0;
            targetX = 0;
            drawingController.capsuleToolbar = false;
          } else if (drawingController.toolbarY >
              viewport.height - snapThreshold - toolbarHeight) {
            targetY = viewport.height - toolbarHeight;
            targetX = 0;
            drawingController.capsuleToolbar = false;
          } else {
            setState(() {
              drawingController.capsuleToolbar = true;
            });
          }

          // if (toolbarX < 0) targetX = 10;
          // if (toolbarX > clampSize.width - 300) {
          //   targetX = clampSize.width - 310;
          // }

          if (targetY != drawingController.toolbarY ||
              targetX != drawingController.toolbarX) {
            _runSnapAnimation(Offset(targetX, targetY));
          }
        },
        child: Container(
          key: drawingController.toolbarKey,
          constraints: BoxConstraints(
            maxWidth: (drawingController.capsuleToolbar)
                ? clampSize.width - 40
                : clampSize.width,
          ),
          child: _buildToolBar(),
        ),
      ),
    );
  }

  Size getSize() {
    final RenderBox? renderBox =
        drawingController.toolbarKey.currentContext?.findRenderObject()
            as RenderBox?;
    if (renderBox != null) {
      final Size size = renderBox.size;
      // final Offset position = renderBox.localToGlobal(Offset.zero);

      return size;
    }
    return Size(0, 0);
  }

  void _runSnapAnimation(Offset targetPosition) {
    drawingController.dockAnimation = Tween<Offset>(
      begin: Offset(drawingController.toolbarX, drawingController.toolbarY),
      end: targetPosition,
    ).animate(drawingController.dockController);

    drawingController.dockController.reset();
    drawingController.dockController.forward();
  }

  Widget _buildToolBar() {
    return ClipRRect(
      borderRadius: (drawingController.capsuleToolbar)
          ? BorderRadius.circular(50)
          : BorderRadius.circular(0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 40,
          width: (drawingController.capsuleToolbar) ? null : clampSize.width,
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
                    drawingController.undo();
                  },
                ),

                _buildIconBtn(
                  Icons.redo_rounded,
                  drawingController.undoActions.isNotEmpty,
                  false,
                  () {
                    drawingController.redo();
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
}
