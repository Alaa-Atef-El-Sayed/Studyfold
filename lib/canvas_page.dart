import 'dart:async';
import 'dart:io';
import 'dart:math' as Math;
import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:studyfold/Icons/my_custom_icons.dart';
import 'package:studyfold/Utils/drawing_controller.dart';
import 'package:studyfold/canvas_action.dart';
import 'package:studyfold/edit_image_page.dart';
import 'package:studyfold/overlays/border_settings_popup.dart';
import 'package:studyfold/overlays/link_menu_popup.dart';
import 'package:studyfold/models/canvas_element.dart';
import 'package:studyfold/models/element_type.dart';
import 'package:studyfold/models/hive_shape.dart';
import 'package:studyfold/models/hive_stroke.dart';
import 'package:studyfold/models/movable_element.dart';
import 'package:studyfold/models/movable_element_data.dart';
import 'package:studyfold/models/shape_type.dart';
import 'package:studyfold/models/stroke_type.dart';
import 'package:studyfold/models/canvas.dart' as hive_canvas;
import 'package:studyfold/overlays/pen_settings_button.dart';
import 'package:studyfold/models/shape_config.dart';
import 'package:studyfold/services/folder_service.dart';
import 'package:studyfold/overlays/shape_menu_popup.dart';
import 'package:studyfold/stroke.dart';
import 'package:studyfold/widgets/color_circle.dart';
import 'package:studyfold/widgets/drawing_board_widget.dart';

class CanvasPage extends StatefulWidget {
  final String canvasId;
  final FolderService folderService;
  const CanvasPage({
    super.key,
    required this.canvasId,
    required this.folderService,
  });

  @override
  State<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends State<CanvasPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  Timer? _autoSaveTimer;
  late DrawingController _drawingController;

  @override
  void initState() {
    super.initState();

    final AnimationController initialDockController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    WidgetsBinding.instance.addObserver(this);
    // hive_canvas.Canvas canvas =
    //     widget.folderService.getItemById(widget.canvasId)['file']
    //         as hive_canvas.Canvas;

    final List<CanvasElement> initialElements = widget.folderService
        .getCanvasElements(widget.canvasId);

    _drawingController = DrawingController()
      ..elements = initialElements
      ..dockController = initialDockController;
    _drawingController.init();
  }
  // _initializeBackgroundCanvas();
  // transformationController.addListener(() {
  //   setState(() {});
  // });

  @override
  void dispose() {
    _saveCanvas();
    _autoSaveTimer?.cancel();
    _drawingController.dockController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _saveCanvas();
    }
  }

  Future<void> _saveCanvas() async {
    // todo
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

    widget.folderService.updateCanvasElements(
      widget.canvasId,
      _drawingController.elements,
    );
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
            opacity: (_drawingController.isPanMode) ? 0.5 : 1,
            child: IconButton(
              onPressed: () {
                setState(() {
                  _drawingController.isPanMode = !_drawingController.isPanMode;
                });
              },
              icon: const Icon(Icons.pan_tool),
            ),
          ),
        ],
      ),
      body: DrawingBoardWidget(
        drawingController: _drawingController,
        canvasSize: Size(3000, 3000),
        onAddImageRequested: _addImage,
        onAddDocumentRequested: _addDocument,
        onEditImageRequested: _editImage,
      ),
    );
  }

  void _editImage({required CanvasElement element}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditImagePage(
          parentId: widget.canvasId,
          element: element,
          folderService: widget.folderService,
        ),
      ),
    );

    final runtimeImage = _drawingController.images.firstWhere(
      (img) => img.id == element.movableElement!.id,
    );

    runtimeImage.cropRectStart = element.movableElement!.cropRectStart;
    runtimeImage.cropRectEnd = element.movableElement!.cropRectEnd;
    runtimeImage.originalWidth = element.movableElement!.originalWidth;
    runtimeImage.originalHeight = element.movableElement!.originalHeight;

    setState(() {});
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
    // Strip away the infinity and the Stack centering.
    // Force the image to strictly adhere to the exact width and height coordinates!
    return SizedBox(
      width: width,
      height: height,
      child: Image.file(
        File(imagePath),
        fit: BoxFit.fill, // Guarantees no invisible letterboxing
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

class ElementsPainter extends CustomPainter {
  final List<CanvasElement> elements;
  final Rect viewport;

  ElementsPainter({required this.elements, required this.viewport});

  @override
  void paint(Canvas canvas, Size size) {
    for (final element in elements) {
      final HiveStroke stroke = element.stroke!;
      if (viewport.overlaps(
        Rect.fromPoints(stroke.bounds.topLeft, stroke.bounds.bottomRight),
      )) {
        canvas.drawPath(stroke.path, stroke.paint);
        // canvas.drawRect(
        //   stroke.bounds,
        //   Paint()
        //     ..style = PaintingStyle.stroke
        //     ..color = Colors.red,
        // );
      }
      // canvas.drawPath(stroke.path, stroke.paint);
    }
  }

  @override
  bool shouldRepaint(covariant ElementsPainter oldDelegate) {
    return oldDelegate.elements != elements;
  }
}
