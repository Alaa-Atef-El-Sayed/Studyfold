import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:studyfold/models/movable_element.dart';
import 'package:studyfold/models/movable_element_data.dart';
import 'package:studyfold/models/note.dart';
import 'package:studyfold/models/element_type.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:studyfold/pdfscreenshothelper.dart';
import 'package:path/path.dart' as p;
import 'package:studyfold/services/folder_service.dart';

enum MediaType { image, audio, document, pdf }

class CreateNotePage extends StatefulWidget {
  final String? noteId;
  final String folderId;
  final int page;
  final FolderService folderService;
  const CreateNotePage({
    super.key,
    this.noteId,
    required this.folderId,
    required this.page,
    required this.folderService,
  });

  @override
  State<CreateNotePage> createState() => _CreateNotePageState();
}

class _CreateNotePageState extends State<CreateNotePage> {
  late QuillController _quillController;
  late FocusNode _focusNode;
  List<MovableElement> _movableElements = [];
  late ScrollController _scrollController;
  final TextEditingController _controller = TextEditingController();
  double _scrollOffset = 0.0;
  final player = AudioPlayer();
  bool isPlaying = false;
  double scale = 1;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _quillController = QuillController.basic();
    _scrollController = ScrollController();
    _loadNoteIfEditing();

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _quillController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    player.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Note'),
        actions: [IconButton(icon: Icon(Icons.save), onPressed: _saveNote)],
      ),
      body: Column(
        children: [
          QuillSimpleToolbar(
            controller: _quillController,
            config: QuillSimpleToolbarConfig(
              buttonOptions: QuillSimpleToolbarButtonOptions(
                fontSize: QuillToolbarFontSizeButtonOptions(
                  items: Map.fromEntries([
                    MapEntry('ez bro', '8'),
                    MapEntry('normal', '12'),
                    MapEntry('large', '16'),
                    MapEntry('huge', '20'),
                  ]),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () {
                  if (scale > 2.5) return;
                  setState(() {
                    scale += 0.1;
                  });
                },
                icon: const Icon(Icons.add, size: 36),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () {
                  if (scale < 0.3) return;
                  setState(() {
                    scale -= 0.1;
                  });
                },
                icon: const Icon(Icons.remove, size: 36),
              ),
              const SizedBox(width: 10),
            ],
          ),

          Expanded(
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: NotificationListener<ScrollMetricsNotification>(
                onNotification: (notification) {
                  setState(() {
                    _scrollOffset = notification.metrics.pixels;
                  });
                  return false;
                },
                child: Stack(
                  children: [
                    Container(
                      color: Colors.grey[700],
                      child: SizedBox(
                        width: 500,
                        height: 800,
                        // height: double.infinity,
                        child: QuillEditor.basic(
                          controller: _quillController,
                          scrollController: _scrollController,
                          config: QuillEditorConfig(
                            // scrollPhysics: NeverScrollableScrollPhysics()
                            // scrollable: true,
                          ),
                        ),
                      ),
                    ),

                    // Transform.translate(
                    //   offset: Offset(0, -_scrollOffset),
                    //   child: Stack(
                    //     children: _movableElements.map((element) {
                    //       return Positioned(
                    //         left: element.position.dx,
                    //         top: element.position.dy,
                    //         child: GestureDetector(
                    //           onPanUpdate: (details) {
                    //             setState(() {
                    //               element.position += details.delta;
                    //             });
                    //           },
                    //           child: element.widget,
                    //         ),
                    //       );
                    //     }).toList(),
                    //   ),
                    // ),
                    ..._movableElements.map((element) {
                      // Matrix4 transform = Matrix4.identity();
                      // return GestureDetector(
                      //   onPanUpdate: (details) {
                      //     transform = Matrix4.identity()
                      //       ..translate(
                      //         details.localPosition.dx,
                      //         details.localPosition.dy,
                      //       );
                      //     setState(() {});
                      //   },
                      //   child: AnimatedContainer(
                      //     duration: Duration(milliseconds: 500),
                      //     transform: transform,
                      //     child: Positioned(
                      //       left: element.position.dx,
                      //       top: element.position.dy - _scrollOffset,
                      //       child: element.widget
                      //     ),
                      //   ),
                      // );
                      return Positioned(
                        left: element.position.dx,
                        top: element.position.dy - _scrollOffset,
                        child: GestureDetector(
                          onDoubleTap: () {
                            // debugPrint("Double tapped element: ${element.position}");
                            if (element.type == ElementType.document) {
                              debugPrint(
                                "Opening document: ${element.filePath}",
                              );
                              _openDocument(element.filePath!);
                            }
                            if (element.type == ElementType.audio) {
                              debugPrint(
                                "Opening document: ${element.filePath}",
                              );
                              final filePath = element.filePath as String;
                              _playAudio(filePath);
                            }
                          },
                          onPanUpdate: (details) {
                            setState(() {
                              element.position += details.delta;
                            });
                          },
                          child: element.widget,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: PopupMenuButton<MediaType>(
        onSelected: (type) {
          switch (type) {
            case MediaType.pdf:
              saveAsPdf();
              break;
            case MediaType.image:
              _addImage();
              break;
            case MediaType.audio:
              _addAudio();
              break;
            case MediaType.document:
              _addDocument();
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: MediaType.pdf,
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf),
                SizedBox(width: 8),
                Text('Save as PDF'),
              ],
            ),
          ),
          PopupMenuItem(
            value: MediaType.image,
            child: Row(
              children: [
                Icon(Icons.image),
                SizedBox(width: 8),
                Text('Add Image'),
              ],
            ),
          ),
          PopupMenuItem(
            value: MediaType.audio,
            child: Row(
              children: [
                Icon(Icons.audiotrack),
                SizedBox(width: 8),
                Text('Add Audio'),
              ],
            ),
          ),
          PopupMenuItem(
            value: MediaType.document,
            child: Row(
              children: [
                Icon(Icons.description),
                SizedBox(width: 8),
                Text('Add Document'),
              ],
            ),
          ),
        ],
        child: FloatingActionButton(onPressed: null, child: Icon(Icons.add)),
      ),
    );
  }

  void _addAudio() async {
    final FilePicker picker = FilePicker.platform;

    final FilePickerResult? result = await picker.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final String id = DateTime.now().millisecondsSinceEpoch.toString();

      setState(() {
        _movableElements.add(
          MovableElement(
            width: 300,
            height: 80,
            id: id,
            type: ElementType.audio,
            position: Offset(50, 50),
            filePath: file.path!,
            title: file.name,
            widget: _buildAudioWidget(file.path!, file.name, id, 300, 80),
          ),
        );
      });
    }
  }

  Widget _buildAudioWidget(
    String filePath,
    String name,
    String id,
    int width,
    int height,
  ) {
    return Container(
      width: 300,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              _playAudio(filePath);
            },
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            color: Colors.blue,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14),
            ),
          ),

          IconButton(
            onPressed: () {
              setState(() {
                _movableElements.removeWhere((element) => element.id == id);
              });
            },
            icon: Icon(Icons.close, size: 18),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  void _addDocument() async {
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

      setState(() {
        _movableElements.add(
          MovableElement(
            width: 200,
            height: 120,
            id: id,
            type: ElementType.document,
            position: Offset(50, 50),
            filePath: permanentFilePath,
            title: file.name,
            widget: _buildDocumentWidget(
              permanentFilePath,
              file.name,
              id,
              200,
              120,
            ),
          ),
        );
      });
    }
  }

  Widget _buildDocumentWidget(
    String filePath,
    String name,
    String id,
    double width,
    double height,
  ) {
    return Container(
      color: Colors.amber,
      child: Center(
        child: Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _addImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      final String id = DateTime.now().millisecondsSinceEpoch.toString();
      final directory = await getApplicationDocumentsDirectory();
      final String destinationPath = p.join(directory.path, id);
      final sourceFilePath = image.path;
      final File finalFile = await File(sourceFilePath).copy(destinationPath);
      final permanentFilePath = finalFile.path;

      if (await File(sourceFilePath).exists()) {
        await File(sourceFilePath).delete();
      }

      setState(() {
        _movableElements.add(
          MovableElement(
            width: 200,
            height: 150,
            id: id,
            type: ElementType.image,
            position: Offset(50, 50),
            filePath: permanentFilePath,
            widget: _buildImageWidget(permanentFilePath, id, 200, 150),
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Something went wrong")));
    }
  }

  Widget _buildImageWidget(
    String imagePath,
    String id,
    double width,
    double height,
  ) {
    return SizedBox(
      width: width + 10,
      height: height + 10,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Image.file(File(imagePath), fit: BoxFit.fill),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              onPressed: () async {
                if (await File(imagePath).exists()) {
                  await File(imagePath).delete();
                }
                setState(() {
                  _movableElements.removeWhere((element) => element.id == id);
                });
              },
              icon: const Icon(Icons.close, color: Colors.red, size: 26),
            ),
          ),

          // Bottom Right
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onPanUpdate: (details) {
                final element = _movableElements.firstWhere((e) => e.id == id);
                final newWidth = element.width + details.delta.dx;
                final newHeight = element.height + details.delta.dy;

                if (newWidth > 50 && newHeight > 50) {
                  setState(() {
                    element.width = newWidth;
                    element.height = newHeight;
                    element.widget = _buildImageWidget(
                      imagePath,
                      id,
                      newWidth,
                      newHeight,
                    );
                  });
                }
              },
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // Bottom Left
          Positioned(
            left: 0,
            bottom: 0,
            child: GestureDetector(
              onPanUpdate: (details) {
                final element = _movableElements.firstWhere((e) => e.id == id);
                final newWidth = element.width - details.delta.dx;
                final newHeight = element.height + details.delta.dy;

                if (newWidth > 50 && newHeight > 50) {
                  setState(() {
                    element.width = newWidth;
                    element.height = newHeight;
                    element.position = Offset(
                      element.position.dx + details.delta.dx,
                      element.position.dy,
                    );

                    element.widget = _buildImageWidget(
                      imagePath,
                      id,
                      newWidth,
                      newHeight,
                    );
                  });
                }
              },
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // Top Left
          Positioned(
            left: 0,
            top: 0,
            child: GestureDetector(
              onPanUpdate: (details) {
                final element = _movableElements.firstWhere((e) => e.id == id);
                final newWidth = element.width - details.delta.dx;
                final newHeight = element.height - details.delta.dy;

                if (newWidth > 50 && newHeight > 50) {
                  setState(() {
                    element.width = newWidth;
                    element.height = newHeight;
                    element.position = Offset(
                      element.position.dx + details.delta.dx,
                      element.position.dy + details.delta.dy,
                    );

                    element.widget = _buildImageWidget(
                      imagePath,
                      id,
                      newWidth,
                      newHeight,
                    );
                  });
                }
              },
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // Top Right
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onPanUpdate: (details) {
                final element = _movableElements.firstWhere((e) => e.id == id);
                final newWidth = element.width + details.delta.dx;
                final newHeight = element.height - details.delta.dy;

                if (newWidth > 50 && newHeight > 50) {
                  setState(() {
                    element.width = newWidth;
                    element.height = newHeight;
                    element.position = Offset(
                      element.position.dx,
                      element.position.dy + details.delta.dy,
                    );

                    element.widget = _buildImageWidget(
                      imagePath,
                      id,
                      newWidth,
                      newHeight,
                    );
                  });
                }
              },
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // void _addImage() async {
  //   final ImagePicker picker = ImagePicker();
  //   final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  //   final String id = DateTime.now().millisecondsSinceEpoch.toString();

  //   if (image != null) {
  //     setState(() {
  //       _movableElements.add(
  //         MovableElement(
  //           id: id,
  //           type: ElementType.image,
  //           position: Offset(50, 50),
  //           filePath: image.path,
  //           widget: ResizableImage(
  //             imagePath: image.path,
  //             onDelete: () {
  //               setState(() {
  //                 _movableElements.removeWhere((element) => element.id == id);
  //               });
  //             },
  //             onResize: (newSize) {

  //             },
  //           ),
  //         ),
  //       );
  //     });
  //   }
  // }
  void _saveNote() {
    Map<String, dynamic> freePositionResult = {};
    Offset position = Offset.zero;
    int page = widget.page;
    if (widget.noteId == null) {
      if (widget.page == -1) {
        freePositionResult = widget.folderService.getNextFreePosition(
          false,
          widget.folderId,
          1,
        );
        position = freePositionResult['position'];
        page = freePositionResult['page'];
        if (page == -1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Something went wrong..."),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      } else {
        freePositionResult = widget.folderService.getNextFreePosition(
          false,
          widget.folderId,
          widget.page,
        );
        position = freePositionResult['position'];
      }
    } else {
      //todo
    }
    final document = _quillController.document.toDelta().toJson();

    final movableElementsData = _movableElements.map((element) {
      return element.toData();
    }).toList();

    final note = Note(
      id: widget.noteId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      folderId: widget.folderId,
      title: _getNoteTitle(),
      document: document,
      positionX: position.dx,
      positionY: position.dy,
      page: page,
      movableElements: movableElementsData,
    );

    final noteBox = Hive.box<Note>('notes');
    noteBox.put(note.id, note);

    Navigator.pop(context);
  }

  String _getNoteTitle() {
    final firstLine = _quillController.document
        .toPlainText()
        .split('\n')
        .first
        .trim();
    return firstLine.isNotEmpty ? firstLine : 'Untitled Note';
  }

  void _loadNoteIfEditing() async {
    if (widget.noteId != null) {
      final noteBox = Hive.box<Note>('notes');
      final Note? note = noteBox.get(widget.noteId);

      if (note != null) {
        setState(() {
          _quillController = QuillController(
            document: Document.fromJson(note.document),
            // readOnly: true,
            selection: const TextSelection.collapsed(offset: 0),
          );

          _movableElements = note.movableElements.map((data) {
            return _createMovableElementFromData(data);
          }).toList();
        });
      }
    }
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
        data.title ?? 'Document',
        data.id,
        data.width,
        data.height,
      );
    } else {
      widget = Container();
    }

    return MovableElement.fromData(data, widget);
  }

  void _playAudio(String filePath) async {
    try {
      if (isPlaying) {
        await player.pause();
        setState(() {
          isPlaying = false;
        });
      } else {
        await player.setFilePath(filePath);
        await player.play();
        setState(() {
          isPlaying = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Audio error: $e')));
    }
  }

  void _openDocument(String filePath) async {
    try {
      final result = await OpenFile.open(filePath, type: 'application/pdf');

      if (!mounted) return;
      switch (result.type) {
        case ResultType.done:
          // Successfully opened
          break;
        case ResultType.noAppToOpen:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Found no apps that can open that file')),
          );
          break;
        case ResultType.fileNotFound:
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('PDF file not found')));
          break;
        case ResultType.permissionDenied:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Permission denied to open PDF')),
          );
          break;
        case ResultType.error:
        default:
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${result.message}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open PDF: $e')));
    }
  }

  Future<void> saveAsPdf() async {
    saveAsPdfWithScreenshots();
    final hasPermission = await _requestStoragePermission();
    if (hasPermission) {
      final pdf = pw.Document();

      final imageBytesList = await Future.wait(
        _movableElements
            .where((e) => e.type == ElementType.image)
            .map((e) => _fileToBytes(e.filePath!)),
      );

      final List images = [];
      // final Map<String, dynamic> images = {};

      int i = -1;
      for (final bytes in imageBytesList) {
        i++;
        if (bytes.isNotEmpty) {
          final Map<String, dynamic> img = {
            'bytes': bytes,
            'width': _movableElements
                .where((e) => e.type == ElementType.image)
                .toList()[i]
                .width,
            'height': _movableElements
                .where((e) => e.type == ElementType.image)
                .toList()[i]
                .height,
            'dx': _movableElements
                .where((e) => e.type == ElementType.image)
                .toList()[i]
                .position
                .dx,
            'dy': _movableElements
                .where((e) => e.type == ElementType.image)
                .toList()[i]
                .position
                .dy,
          };
          images.add(img);
        }
      }

      // final Delta delta = _quillController.document.toDelta();

      // for(final op in delta.operations) {
      //   if(op.attributes != null && op.attributes!.containsKey(Attribute.font.key)) {
      //     final String? fontFamily = op.attributes![Attribute.font.key];
      //     debugPrint('Font family found: ${op.data.toString()}');
      //   }
      // }

      // for(final op in delta.operations) {
      //   if(op.attributes != null && op.attributes!.containsKey(Attribute.bold.key)) {
      //     debugPrint('Bold Font: ${op.data.toString()}');
      //   }
      // }

      // for (final op in delta.operations) {
      // if(op.attributes != null && op.attributes!.containsKey('size')) {
      // final sizeValue = op.attributes!['size'];

      // debugPrint('Bold Font: ${op.attributes}');
      // }
      // }

      const pageHeight = 800.0;
      const pageWidth = 500.0;

      final double pageWidthInPoints = pixelsToPoints(pageWidth);
      final double marginInPoints = pixelsToPoints(20);
      final double contentWidthInPoints =
          pageWidthInPoints - (2 * marginInPoints);

      for (final img in images) {
        debugPrint(PdfPoint(img['dx'], -img['dy']).toString());
      }

      final int pages = images.where((img) => img['dy'] < pageHeight).length;
      debugPrint('Total pages needed: $pages');

      final container = pw.Container(
        child: pw.Paragraph(
          text: _quillController.document.toPlainText(),
          style: pw.TextStyle(fontSize: 15),
        ),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat(540, 840, marginAll: 20),
          build: (pw.Context context) => [
            // pw.Expanded(
            // child: pw.Stack(
            //   children: [
            //     pw.Container(
            //       width: 500,
            //       child: pw.Paragraph(
            //         text: _quillController.document.toPlainText(),
            //         style: pw.TextStyle(fontSize: 10.5),
            //       ),
            //     ),
            //     for (final img in images)
            //       pw.Transform.translate(
            //         offset: PdfPoint(img['dx'], -img['dy']),
            //         // offset: PdfPoint(0, 0),
            //         child: pw.Container(
            //           alignment: pw.Alignment.center,
            //           width: img['width'],
            //           height: img['height'],
            //           child: pw.Image(
            //             pw.MemoryImage(img['bytes']),
            //             width: img['width'],
            //             height: img['height'],
            //             fit: pw.BoxFit.fill,
            //           ),
            //         ),
            //       ),
            //   ],
            // ),
            // child: pw.Column(
            //   children: [
            pw.Paragraph(
              text: _quillController.document.toPlainText(),
              style: pw.TextStyle(fontSize: 16),
            ),
            for (final img in images)
              pw.Transform.translate(
                offset: PdfPoint(img['dx'], -img['dy']),
                // offset: PdfPoint(0, 0),
                child: pw.Container(
                  alignment: pw.Alignment.center,
                  width: img['width'],
                  height: img['height'],
                  child: pw.Image(
                    pw.MemoryImage(img['bytes']),
                    width: img['width'],
                    height: img['height'],
                    fit: pw.BoxFit.fill,
                  ),
                ),
              ),
            //   ],
            // ),
            // ),
          ],
        ),
      );

      // pdf.editPage(
      //   0,
      //   pw.Page(
      //     pageFormat: PdfPageFormat(540, 840, marginAll: 20),
      //     build: (pw.Context context) {
      //       final img = images[0];
      //       return pw.Transform.translate(
      //         offset: PdfPoint(img['dx'], -img['dy']),
      //         // offset: PdfPoint(0, 0),
      //         child: pw.Container(
      //           alignment: pw.Alignment.center,
      //           width: img['width'],
      //           height: img['height'],
      //           child: pw.Image(
      //             pw.MemoryImage(img['bytes']),
      //             width: img['width'],
      //             height: img['height'],
      //             fit: pw.BoxFit.fill,
      //           ),
      //         ),
      //       );
      //     },
      //   ),
      // );

      Directory? directory;
      directory = await getApplicationDocumentsDirectory();
      directory = Directory('/storage/emulated/0/Download');
      final fileName = "${DateTime.now().millisecondsSinceEpoch}ez.pdf";
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      debugPrint('PDF saved successfully at: ${file.path}');
      // await Printing.sharePdf(bytes: await pdf.save(), filename: 'note.pdf');
    }
  }

  Future<void> saveAsPdfWithScreenshots() async {
    final pdf = pw.Document();
    final screenshotHelper = ScreenshotHelper(); // Create instance

    final screenshot = await screenshotHelper.captureWidget(
      Container(
        width: 500,
        height: 800,
        color: Colors.white,
        // child: QuillEditor.basic(controller: _quillController),
        child: Stack(
          children: [
            QuillEditor.basic(controller: _quillController),
            ..._movableElements.map((element) {
              return Positioned(
                left: element.position.dx,
                top: element.position.dy - _scrollOffset,
                child: GestureDetector(
                  onDoubleTap: () {
                    // debugPrint("Double tapped element: ${element.position}");
                    if (element.type == ElementType.document) {
                      debugPrint("Opening document: ${element.filePath}");
                      final filePath = element.filePath as String;
                      _openDocument(filePath);
                    }
                    if (element.type == ElementType.audio) {
                      debugPrint("Opening document: ${element.filePath}");
                      final filePath = element.filePath as String;
                      _playAudio(filePath);
                    }
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      element.position += details.delta;
                    });
                  },
                  child: element.widget,
                ),
              );
            }),
          ],
        ),
      ),
      pixelRatio: 3.0,
    );

    if (screenshot != null) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(540, 840, marginAll: 20),
          build: (pw.Context context) {
            return pw.SizedBox(
              width: 500,
              height: 800,
              child: pw.Image(
                pw.MemoryImage(screenshot),
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );

      Directory? directory = await getApplicationDocumentsDirectory();
      directory = Directory('/storage/emulated/0/Download');
      final fileName =
          "screenshot_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      debugPrint('PDF with screenshot saved at: ${file.path}');
    } else {
      debugPrint('Failed to capture screenshot');
    }
  }

  double pixelsToPoints(double pixels) {
    return pixels * (72.0 / 96.0);
  }

  double pointsToPixels(double points) {
    return points * (96.0 / 72.0);
  }

  Future<Uint8List> _fileToBytes(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      } else {
        throw Exception('File not found: $filePath');
      }
    } catch (e) {
      debugPrint('Error reading file: $e');
      return Uint8List(0);
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (await Permission.storage.request().isGranted) {
      return true;
    }
    return false;
  }
}
