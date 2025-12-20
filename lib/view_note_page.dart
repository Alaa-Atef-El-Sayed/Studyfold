import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart';
import 'package:open_file/open_file.dart';
import 'package:studyfold/models/element_type.dart';
import 'package:studyfold/models/movable_element.dart';
import 'package:studyfold/models/movable_element_data.dart';
import 'package:studyfold/models/note.dart';
import 'package:studyfold/services/folder_service.dart';

class ViewNotePage extends StatefulWidget {
  final String noteId;
  final String folderId;
  final int page;
  final FolderService folderService;
  const ViewNotePage({
    super.key,
    required this.noteId,
    required this.folderId,
    required this.page,
    required this.folderService,
  });

  @override
  State<ViewNotePage> createState() => _ViewNotePageState();
}

class _ViewNotePageState extends State<ViewNotePage> {
  QuillController _quillController = QuillController.basic();
  List<MovableElement> _movableElements = [];
  final ScrollController _scrollController = ScrollController();
  final player = AudioPlayer();
  double _scrollOffset = 0.0;
  bool isPlaying = false;
  double scale = 1;

  @override
  void initState() {
    super.initState();
    _loadNoteData();
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
    _scrollController.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('View Note')),
      body: Column(
        children: [
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
                        child: QuillEditor.basic(
                          controller: _quillController,
                          scrollController: _scrollController,
                        ),
                      ),
                    ),

                    ..._movableElements.map((element) {
                      return Positioned(
                        left: element.position.dx,
                        top: element.position.dy - _scrollOffset,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onDoubleTap: () {
                            if (element.type == ElementType.document) {
                              _openDocument(element.filePath!);
                            }
                            if (element.type == ElementType.audio) {
                              final filePath = element.filePath as String;
                              _playAudio(filePath);
                            }
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
    );
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
        ],
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

  void _loadNoteData() async {
    final noteBox = Hive.box<Note>('notes');
    final Note? note = noteBox.get(widget.noteId);

    if (note != null) {
      setState(() {
        _quillController = QuillController(
          document: Document.fromJson(note.document),
          readOnly: true,
          selection: const TextSelection.collapsed(offset: 0),
        );

        _movableElements = note.movableElements.map((data) {
          return _createMovableElementFromData(data);
        }).toList();
      });
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
}
