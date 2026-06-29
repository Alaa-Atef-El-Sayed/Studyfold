import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:studyfold/Icons/my_custom_icons.dart';
import 'package:studyfold/Utils/drawing_controller.dart';
import 'package:studyfold/Utils/drawing_controller_config.dart';
import 'package:studyfold/canvas_action.dart';
import 'package:studyfold/models/canvas_element.dart';
import 'package:studyfold/models/element_type.dart';
import 'package:studyfold/models/movable_element.dart';
import 'package:studyfold/models/shape_config.dart';
import 'package:studyfold/overlays/border_settings_popup.dart';
import 'package:studyfold/overlays/crop_overlay.dart';
import 'package:studyfold/overlays/link_menu_popup.dart';
import 'package:studyfold/overlays/pen_settings_button.dart';
import 'package:studyfold/overlays/shape_menu_popup.dart';
import 'package:studyfold/services/folder_service.dart';
import 'package:studyfold/widgets/canvas_toolbar.dart';
import 'package:studyfold/widgets/color_circle.dart';
import 'package:studyfold/widgets/drawing_board_widget.dart';
import 'package:studyfold/widgets/element_options_widgets.dart';

enum EditImageOptions { crop, rotate, paint }

class EditImagePage extends StatefulWidget {
  final String parentId;
  final CanvasElement element;
  final FolderService folderService;

  const EditImagePage({
    super.key,
    required this.parentId,
    required this.element,
    required this.folderService,
  });

  @override
  State<EditImagePage> createState() => _EditImagePageState();
}

class _EditImagePageState extends State<EditImagePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late DrawingController _drawingController;
  final ElementOptionsWidgets elementOptionsWidgets = ElementOptionsWidgets();

  EditImageOptions _currentMode = EditImageOptions.crop;
  final ScreenshotController _screenshotController = ScreenshotController();

  Rect? viewport;

  Size? _imageSize;
  Size? _initialImageSize;
  bool _constrainedImageSize = false;

  bool _isClamping = true;

  Rect? _cropRect;

  void _saveImage() {
    for (var image in _drawingController.images) {
      final CanvasElement element = _drawingController.elements.firstWhere(
        (e) => e.movableElement != null && e.movableElement!.id == image.id,
      );

      final index = _drawingController.elements.indexWhere(
        (e) => e.movableElement != null && e.movableElement!.id == image.id,
      );

      if (index != -1) {
        _drawingController.elements[index] = CanvasElement(
          movableElement: image.toData(),
          children: element.children,
        );
      }
    }

    widget.element.children = _drawingController.elements;

    widget.element.movableElement!.originalWidth = _imageSize!.width;
    widget.element.movableElement!.originalHeight = _imageSize!.height;

    // We get the ratio between the REAL original size and our screen-fitted _imageSize
    final double scaleX = widget.element.movableElement!.originalWidth / _imageSize!.width;
    final double scaleY = widget.element.movableElement!.originalHeight / _imageSize!.height;

    // Scale the screen crop coordinates back up to the original parent canvas space
    widget.element.movableElement!.cropRectStart = Offset(
      _cropRect!.left * scaleX,
      _cropRect!.top * scaleY,
    );

    widget.element.movableElement!.cropRectEnd = Offset(
      _cropRect!.right * scaleX,
      _cropRect!.bottom * scaleY,
    );

    widget.folderService.updateCanvasElementChildren(
      widget.parentId,
      widget.element,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _saveImage();
    }
  }

  @override
  void initState() {
    super.initState();

    getCanvasSize();

    final AnimationController initialDockController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    WidgetsBinding.instance.addObserver(this);

    final DrawingControllerConfig config = DrawingControllerConfig()
      ..showToolbar = false
      ..enabled = false
      ..minZoom = 0.8
      ..maxZoom = 5
      ..enableClamping = _isClamping
      ..enableElementOptions = false;

    _drawingController = DrawingController()
      ..elements = widget.element.children
      ..dockController = initialDockController
      ..config = config;
    _drawingController.init();
  }

  @override
  void dispose() {
    _saveImage();
    _drawingController.dockController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> getCanvasSize() async {
    final File finalFile = File(widget.element.movableElement!.filePath);

    final Uint8List bytes = await finalFile.readAsBytes();
    final ui.Image decodedImage = await decodeImageFromList(bytes);
    double height = decodedImage.height.toDouble();
    double width = decodedImage.width.toDouble();

    setState(() {
      _imageSize = Size(width, height);
      _initialImageSize = _imageSize;
    });
  }

  void _saveAsImage() async {
    final currentScreenData = MediaQuery.of(context);
    Directory? directory = await getApplicationDocumentsDirectory();

    directory = Directory('/storage/emulated/0/Download');

    final String filePath =
        "${directory.path}/${widget.element.movableElement!.id}.png";

    if (!mounted) return;

    // 1. Calculate how much we need to artificially boost the resolution
    final double exportPixelRatio =
        _initialImageSize!.width / _imageSize!.width;

    _screenshotController
        .captureFromWidget(
          // 2. A simple Directionality wrapper is required for off-screen text
          Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: currentScreenData,
              child: DrawingBoardWidget(
                isExporting: true,
                drawingController: _drawingController,

                canvasSize:
                    _imageSize!, // 💡 Use the SMALL size so coordinates match perfectly!

                onAddImageRequested: _addImage,
                onAddDocumentRequested: _addDocument,
                background: Image.file(
                  File(widget.element.movableElement!.filePath),
                  width: _imageSize!.width,
                  height: _imageSize!.height,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          // 3. THE MAGIC MULTIPLIER: This outputs the 4K/Original resolution image!
          pixelRatio: exportPixelRatio,
          delay: const Duration(
            milliseconds: 200,
          ), // Give it a split second to render
        )
        .then((pngBytes) async {
          try {
            final Uint8List
            compressedJpgBytes = await FlutterImageCompress.compressWithList(
              pngBytes,
              format: CompressFormat.jpeg,
              quality:
                  85, // 85 is the sweet spot: visually identical to 100, but 5x smaller!
            );

            await Gal.putImageBytes(
              compressedJpgBytes,
              album: "Studyfold",
              name: widget.element.movableElement!.id,
            );
            debugPrint(
              "Image successfully saved to Gallery at full resolution!",
            );

            final file = await File(filePath).create();

            file.writeAsBytes(compressedJpgBytes);
          } catch (e) {
            debugPrint("Failed to save image: $e");
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              _saveAsImage();
            },
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: _buildUI(),
      bottomNavigationBar: _buildOptionsBar(),
    );
  }

  Widget _buildPaintBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          elementOptionsWidgets.buildIconBtn(
            Icons.keyboard_arrow_left,
            true,
            false,
            () {
              setState(() {
                setState(() {
                  _currentMode = EditImageOptions.crop;
                  _drawingController.config.enabled = false;
                });
              });
            },
          ),

          elementOptionsWidgets.buildIconBtn(
            Icons.undo_rounded,
            _drawingController.actions.isNotEmpty,
            false,
            () {
              setState(() {
                _drawingController.undo();
              });
            },
          ),

          elementOptionsWidgets.buildIconBtn(
            Icons.redo_rounded,
            _drawingController.undoActions.isNotEmpty,
            false,
            () {
              setState(() {
                _drawingController.redo();
              });
            },
          ),

          SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
              child: VerticalDivider(
                width: 1,
                color: Colors.grey.withValues(alpha: 0.3),
              ),
            ),
          ),

          PenSettingsButton(
            key: _drawingController.penButtonKey,
            currentSize: _drawingController.selectedSize,
            currentColor: _drawingController.selectedColor,
            penButtonKey: _drawingController.penButtonKey,
            isSelected:
                _drawingController.currentDrawMode == CanvasDrawMode.brush,
            setSelected: () {
              setState(() {
                _drawingController.currentDrawMode = CanvasDrawMode.brush;
              });
            },
            onSizeChanged: (newSize) {
              setState(() => _drawingController.selectedSize = newSize);
            },
            onColorChanged: (newColor) {
              setState(() {
                _drawingController.selectedColor = newColor;
                _drawingController.currentDrawMode == CanvasDrawMode.brush;
              });
            },
          ),

          elementOptionsWidgets.buildIconBtn(
            Icons.delete,
            true,
            _drawingController.currentDrawMode == CanvasDrawMode.eraser,
            () {
              setState(() {
                _drawingController.currentDrawMode = CanvasDrawMode.eraser;
              });
            },
          ),

          const SizedBox(width: 8),

          ColorCircle(
            selectedColor: _drawingController.selectedColor,
            onTap: () {
              ColorCircle.showColorPickerDialog(
                selectedColor: _drawingController.selectedColor,
                context: context,
                onColorChanged: (color) => setState(() {
                  _drawingController.currentDrawMode == CanvasDrawMode.brush;
                  _drawingController.selectedColor = color;
                }),
              );
            },
          ),

          LinkMenuPopup(
            key: _drawingController.linkMenuKey,
            addImage: () {
              _addImage(viewport!);
            },
            addDocument: () {
              _addDocument(viewport!);
            },
            linkMenuKey: _drawingController.linkMenuKey,
          ),

          ShapeMenuPopup(
            key: _drawingController.shapeButtonKey,
            currentConfig: _drawingController.currentShapeConfig,
            isSelected:
                _drawingController.currentDrawMode == CanvasDrawMode.shape,
            shapeToolKey: _drawingController.shapeButtonKey,
            setSelected: () {
              setState(() {
                _drawingController.currentDrawMode = CanvasDrawMode.shape;
              });
            },
            onConfigChanged: (newConfig) {
              setState(() {
                _drawingController.currentShapeConfig = newConfig;
                _drawingController.currentShape = newConfig.shapeType;
                // switch (_drawingController.currentShapeConfig.shapeTypeEnum) {
                //   case ShapeTypeEnum.rectangle:
                //     _drawingController.currentShape = ShapeType.rectangle;
                //     break;
                //   case ShapeTypeEnum.circle:
                //     _drawingController.currentShape = ShapeType.circle;
                //     break;
                //   case ShapeTypeEnum.triangle:
                //     _drawingController.currentShape = ShapeType.rectangle;
                //     break;
                //   case ShapeTypeEnum.line:
                //     _drawingController.currentShape = ShapeType.rectangle;
                //     break;
                // }
              });
            },
          ),

          elementOptionsWidgets.buildIconBtn(
            (_drawingController.canvasMode == CanvasMode.edit)
                ? Icons.back_hand
                : Icons.draw_rounded,
            true,
            false,
            () {
              setState(() {
                switch (_drawingController.canvasMode) {
                  case CanvasMode.draw:
                    _drawingController.canvasMode = CanvasMode.edit;
                    break;
                  case CanvasMode.edit:
                    _drawingController.canvasMode = CanvasMode.draw;
                    break;
                }
              });
            },
          ),

          elementOptionsWidgets.buildSelectableElementOption(
            "Enable Clamping",
            Icons.call_made_sharp,
            _isClamping,
            () {
              setState(() {
                _isClamping = !_isClamping;
                _drawingController.config.enableClamping = _isClamping;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.white.withValues(alpha: 0.75),
          padding: const EdgeInsets.all(8.0),
          // 💡 AnimatedBuilder listens to the controller for selection changes!
          child: AnimatedBuilder(
            animation: _drawingController,
            builder: (context, child) {
              // 💡 Determine which row to show
              Widget currentActiveRow;
              if (_drawingController.selectedShape != null ||
                  _drawingController.selectedElement != null) {
                currentActiveRow = _buildElementOptionsRow(
                  key: const ValueKey('element_mode'),
                );
              } else if (_currentMode == EditImageOptions.paint) {
                // Ensure your _buildPaintBar returns a widget with this key!
                currentActiveRow = KeyedSubtree(
                  key: const ValueKey('paint_mode'),
                  child: _buildPaintBar(),
                );
              } else {
                currentActiveRow = _buildDefaultOptionsRow(
                  key: const ValueKey('default_mode'),
                );
              }

              // 💡 AnimatedSwitcher handles the cross-fade automatically
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SizeTransition(
                      sizeFactor: animation,
                      axisAlignment: -1.0,
                      child: child,
                    ),
                  );
                },
                child: currentActiveRow,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultOptionsRow({required Key key}) {
    return Row(
      key: key,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        elementOptionsWidgets.buildSelectableElementOption(
          "Crop",
          Icons.crop,
          _currentMode == EditImageOptions.crop,
          () {
            setState(() {
              _currentMode = EditImageOptions.crop;
            });
          },
        ),
        elementOptionsWidgets.buildSelectableElementOption(
          "Rotate",
          Icons.rotate_left_sharp,
          _currentMode == EditImageOptions.rotate,
          () {
            setState(() {
              _currentMode = EditImageOptions.rotate;
            });
          },
        ),
        elementOptionsWidgets.buildSelectableElementOption(
          "Paint",
          Icons.edit,
          _currentMode == EditImageOptions.paint,
          () {
            setState(() {
              _currentMode = EditImageOptions.paint;
              _drawingController.config.enabled = true;
            });
          },
        ),
      ],
    );
  }

  // Widget _buildOptionsBar() {
  //   return ClipRRect(
  //     borderRadius: BorderRadiusGeometry.vertical(top: Radius.circular(10)),
  //     child: BackdropFilter(
  //       filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
  //       child: Container(
  //         color: Colors.white.withValues(alpha: 0.75),
  //         child: Padding(
  //           padding: const EdgeInsets.all(8.0),
  //           child: _buildOptionsRow(),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildOptionsRow() {
    if (_currentMode == EditImageOptions.paint) {
      return _buildPaintBar();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        elementOptionsWidgets.buildSelectableElementOption(
          "Crop",
          Icons.crop,
          _currentMode == EditImageOptions.crop,
          () {
            setState(() {
              _currentMode = EditImageOptions.crop;
            });
          },
        ),

        elementOptionsWidgets.buildSelectableElementOption(
          "Rotate",
          Icons.rotate_left_sharp,
          _currentMode == EditImageOptions.rotate,
          () {
            setState(() {
              _currentMode = EditImageOptions.rotate;
            });
          },
        ),

        elementOptionsWidgets.buildSelectableElementOption(
          "Paint",
          Icons.edit,
          _currentMode == EditImageOptions.paint,
          () {
            setState(() {
              _currentMode = EditImageOptions.paint;
              _drawingController.config.enabled = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildElementOptionsRow({required Key key}) {
    return Row(
      key: key,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 1. Deselect / Back Button
        elementOptionsWidgets.buildIconBtn(Icons.close, true, false, () {
          setState(() {
            _drawingController.selectedShape = null;
          });
        }),

        const SizedBox(height: 30, child: VerticalDivider(width: 1)),

        if (_drawingController.selectedShape != null)
          elementOptionsWidgets.buildSelectableElementOption(
            "Lock",
            (_drawingController.selectedShape!.shape!.config.isLocked)
                ? Icons.lock_outline
                : Icons.lock_open,
            (_drawingController.selectedShape!.shape!.config.isLocked),
            () {
              setState(() {
                final ShapeConfig oldConfig =
                    _drawingController.selectedShape!.shape!.config;
                _drawingController.selectedShape!.shape!.config = oldConfig
                    .copyWith(isLocked: !oldConfig.isLocked);
              });
            },
          ),

        if (_drawingController.selectedShape != null)
          BorderSettingsPopup(
            key: ValueKey(_drawingController.selectedShape.hashCode),
            shape: _drawingController.selectedShape!.shape!,
            onConfigChanged: (newConfig) {
              setState(() {
                _drawingController.selectedShape!.shape!.config = newConfig;
              });
            },
            onDimensionsChanged: (newDimensions) {
              final currentShape = _drawingController.selectedShape!.shape!;

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
              () => _drawingController.selectedShape!.shape!.colorValue = color
                  .toARGB32(),
            ),
          ),

        // 2. Delete Button
        elementOptionsWidgets.buildSelectableElementOption(
          "Delete",
          Icons.delete_outline,
          false,
          () {
            // _drawingController.deleteSelected();
            // _drawingController.deselectAll();
          },
        ),

        // 3. Duplicate Button (if you have this feature)
        elementOptionsWidgets.buildSelectableElementOption(
          "Duplicate",
          Icons.copy,
          false,
          () {
            // _drawingController.duplicateSelected();
          },
        ),

        // 4. Send to Back / Bring to Front (Optional)
        elementOptionsWidgets.buildSelectableElementOption(
          "Layer",
          Icons.layers_outlined,
          false,
          () {
            // Logic to move element up/down the stack
          },
        ),
      ],
    );
  }

  Widget _buildUI() {
    if (_imageSize == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        viewport = _drawingController.calculateViewport(constraints.biggest);

        if (!_constrainedImageSize) {
          final double aspectRatio = _imageSize!.width / _imageSize!.height;
          if (_imageSize!.width > _imageSize!.height) {
            final double width =
                constraints.maxWidth - constraints.maxWidth / 10;
            final double height = width / aspectRatio;
            _imageSize = Size(width, height);
          } else {
            final double height =
                constraints.maxHeight - constraints.maxHeight / 8;
            final double width = height * aspectRatio;
            _imageSize = Size(width, height);
          }

          _drawingController.centerViewport(constraints.biggest, _imageSize!);

          _drawingController.config.clampUpperLimitX = _imageSize!.width;
          _drawingController.config.clampUpperLimitY = _imageSize!.height;

          _drawingController.config.clampCenterX = _imageSize!.width / 2;
          _drawingController.config.clampCenterY = _imageSize!.height / 2;

          final movable = widget.element.movableElement!;
          // Calculate scale from original parent coordinates down to our screen coordinates
          if (_cropRect == null) {
            final double scaleX = _imageSize!.width / movable.originalWidth;
            final double scaleY = _imageSize!.height / movable.originalHeight;

            debugPrint(movable.cropRectStart.toString());

            _cropRect = Rect.fromPoints(
              Offset(
                movable.cropRectStart.dx * scaleX,
                movable.cropRectStart.dy * scaleY,
              ),
              Offset(
                movable.cropRectEnd.dx * scaleX,
                movable.cropRectEnd.dy * scaleY,
              ),
            );
          }
          _constrainedImageSize = true;
        }
        // _cropRect ??= Rect.fromLTWH(
        //   0,
        //   0,
        //   _imageSize!.width,
        //   _imageSize!.height,
        // );

        // final double dx = (constraints.biggest.width - _imageSize!.width) / 2;
        // final double dy = (constraints.biggest.height - _imageSize!.height) / 2;

        return Stack(
          children: [
            DrawingBoardWidget(
              drawingController: _drawingController,
              canvasSize: _imageSize!,
              onAddImageRequested: _addImage,
              onAddDocumentRequested: _addDocument,
              showCropOverlay: _currentMode == EditImageOptions.crop,
              initialCropRect: _cropRect,
              onCropChanged: (newRect) {
                setState(() => _cropRect = newRect);
              },
              background: Image.file(
                File(widget.element.movableElement!.filePath),
                width: _imageSize!.width,
                height: _imageSize!.height,
                fit: BoxFit.fill,
              ),
            ),

            // if (_currentMode == EditImageOptions.crop)
            //   Center(
            //     child: CropOverlay(
            //       inverseScale: 1,
            //       imageSize: _imageSize!,
            //       initialCropRect: _cropRect!,
            //       onCropChanged: (newRect) {
            //         _cropRect = newRect;
            //       },
            //     ),
            //   ),
            // CanvasToolbar(
            //   drawingController: _drawingController,
            //   clampSize: viewport.size,
            //   onAddImageRequested: _addImage,
            //   onAddDocumentRequested: _addDocument,
            //   viewport: viewport,
            // ),
          ],
        );
      },
    );
  }

  void _addImage(Rect viewport) async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    final directory = await getApplicationDocumentsDirectory();
    final String destinationPath = p.join(directory.path, id);
    final sourceFilePath = image.path;
    final File finalFile = await File(sourceFilePath).copy(destinationPath);
    final permanentFilePath = finalFile.path;

    if (await File(sourceFilePath).exists()) {
      await File(sourceFilePath).delete();
    }

    final Uint8List bytes = await finalFile.readAsBytes();
    final ui.Image decodedImage = await decodeImageFromList(bytes);
    double height = decodedImage.height.toDouble();
    double width = decodedImage.width.toDouble();
    final double aspectRatio = width / height;
    width = 200;
    height = width / aspectRatio;

    MovableElement movableElement = MovableElement(
      width: width,
      height: height,
      id: id,
      aspectRatio: aspectRatio,
      type: ElementType.image,
      position: viewport.center,
      filePath: permanentFilePath,
      widget: _buildImageWidget(permanentFilePath, id, width, height),
    );

    widget.folderService.createFile(parentId: id, filePath: permanentFilePath);
    widget.folderService.createMovableElement(movableElement: movableElement);

    setState(() {
      _drawingController.images.add(movableElement);
      _drawingController.elements.add(
        CanvasElement(movableElement: movableElement.toData()),
      );
    });
  }

  void _addDocument(Rect viewport) async {
    final FilePicker picker = FilePicker.platform;

    final FilePickerResult? result = await picker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final String id = '${DateTime.now().millisecondsSinceEpoch}.pdf';
      final directory = await getApplicationDocumentsDirectory();
      final String destinationPath = p.join(directory.path, id);
      final sourceFilePath = file.path!;
      final File finalFile = await File(sourceFilePath).copy(destinationPath);
      final permanentFilePath = finalFile.path;

      if (await File(sourceFilePath).exists()) {
        await File(sourceFilePath).delete();
      }

      final movableElement = MovableElement(
        width: 200,
        height: 120,
        id: id,
        type: ElementType.document,
        position: viewport.center,
        filePath: permanentFilePath,
        aspectRatio: 200 / 120,
        title: file.name,
        widget: _buildDocumentWidget(
          permanentFilePath,
          file.name,
          id,
          200,
          120,
        ),
      );

      widget.folderService.createFile(
        parentId: id,
        filePath: permanentFilePath,
      );

      widget.folderService.createMovableElement(movableElement: movableElement);

      setState(() {
        _drawingController.documents.add(movableElement);
      });
    }
  }

  Widget _buildImageWidgetee(
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
        ],
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
      width: width,
      height: height,
      child: Image.file(File(imagePath), fit: BoxFit.fill),
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
}
