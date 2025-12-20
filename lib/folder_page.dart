import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:studyfold/canvas_page.dart';
import 'package:studyfold/create_note_page.dart';
import 'package:studyfold/create_quiz_page.dart';
import 'package:studyfold/edit_folder_page.dart';
import 'package:studyfold/edit_pdf_page.dart';
import 'package:studyfold/models/file_base.dart';
import 'package:studyfold/models/audio_file.dart';
import 'package:studyfold/models/folder.dart';
import 'package:studyfold/models/movable_element_data.dart';
import 'package:studyfold/models/note.dart';
import 'package:studyfold/models/pdf.dart';
import 'package:studyfold/models/quiz.dart';
import 'package:studyfold/models/canvas.dart';
import 'package:studyfold/move_mode_page.dart';
import 'package:studyfold/services/folder_service.dart';
import 'package:studyfold/models/element_type.dart';
import 'package:path/path.dart' as p;
import 'package:studyfold/services/settings_service.dart';
import 'package:studyfold/view_note_page.dart';

enum FileTypeCustom { folder, note, pdf, audio, canvas, quiz }

enum QuizQuestionType { mcq1, mcq2, written }

class FolderPage extends StatefulWidget {
  final FolderService folderService;
  final Folder folder;
  final bool isMovingMode;
  final Set<String> selectedItemIds;
  final void Function(bool done)? onCancel;
  final String? initialFolderId;
  const FolderPage({
    super.key,
    required this.folderService,
    required this.folder,
    required this.isMovingMode,
    required this.selectedItemIds,
    this.onCancel,
    this.initialFolderId,
  });

  @override
  State<FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {
  final SettingsService _settingsService = SettingsService();
  List<Map<String, dynamic>> itemPreviewHolders = [];
  final TransformationController _transformationController =
      TransformationController();
  static const double desktopWidth = 2000;
  static const double desktopHeight = 2000;
  Offset _startOffset = Offset.zero;
  Offset _startGlobalOffset = Offset.zero;
  bool desktopView = false;
  int grid = 200;
  double currentScale = 1.0;
  bool _isLoading = false;
  bool _isCanceled = false;
  int _currentPage = 1;
  int _previousPage = 1;
  bool _isDragging = false;
  List desktopItems = [];
  final GlobalKey _deleteAreaKey = GlobalKey();
  final GlobalKey _sendToPageKey = GlobalKey();
  bool _isOverDeleteArea = false;
  bool _isOverSendToPageArea = false;
  final Set<String> _selectedItemIds = {};
  bool _isSelectionMode = false;
  bool _areAllSelected = false;
  bool _isMovingMode = false;
  // @override
  // void initState() {
  //   super.initState();
  //   desktopView = _settingsService.desktopViewValue;
  // }

  @override
  Widget build(BuildContext context) {
    desktopView = _settingsService.desktopViewValue;
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double appBarHeight = kToolbarHeight;
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        PopScope(
          canPop: !_isLoading && !_isSelectionMode && !_isMovingMode,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && _isSelectionMode) {
              _clearSelection();
            } else if (!didPop && _isMovingMode) {
              setState(() {
                _isSelectionMode = true;
                _isMovingMode = false;
              });
            }
          },
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: !_isSelectionMode || !_isMovingMode,
              leading: (_isSelectionMode && !_isMovingMode)
                  ? Row(
                      children: [
                        IconButton(
                          onPressed: _toggleSelectAll,
                          icon: Icon(
                            (_areAllSelected)
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                          ),
                        ),
                        // Text("${_selectedItemIds.length} items selected"),
                      ],
                    )
                  : null,
              // backgroundColor: Colors.white,
              title: (_isSelectionMode || _isMovingMode)
                  ? Transform.translate(
                      offset: Offset(-30, 0),
                      child: Text('${_selectedItemIds.length} items selected'),
                    )
                  : Center(child: Text(widget.folder.name)),
              actions: [
                (_isSelectionMode || _isMovingMode || widget.isMovingMode)
                    ? Row(
                        children: [
                          (_isMovingMode || widget.isMovingMode)
                              ? Row(
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        // setState(() {
                                        //   _isSelectionMode = true;
                                        //   _isMovingMode = false;
                                        // });
                                        widget.onCancel?.call(false);
                                      },
                                      child: const Text(
                                        "Cancel",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    TextButton(
                                      onPressed:
                                          (widget.folder.id !=
                                              widget.initialFolderId)
                                          ? () {
                                              for (final id
                                                  in widget.selectedItemIds) {
                                                widget.folderService.moveItem(
                                                  id,
                                                  widget.folder.id,
                                                  _currentPage,
                                                );
                                              }
                                              widget.onCancel?.call(true);
                                            }
                                          : null,
                                      child: const Text(
                                        "Move here",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                )
                              : PopupMenuButton(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: "delete",
                                      child: Text("Delete"),
                                    ),
                                    PopupMenuItem(
                                      value: "move",
                                      child: Text("Move"),
                                    ),
                                    PopupMenuItem(
                                      value: "edit",
                                      child: Text("Edit"),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    switch (value) {
                                      case "edit":
                                        final item = widget.folderService
                                            .getItemById(
                                              _selectedItemIds.first,
                                            );
                                        final String type = item['type'];
                                        final file = item['file'];
                                        if (type == 'note') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CreateNotePage(
                                                    noteId:
                                                        _selectedItemIds.first,
                                                    folderId: widget.folder.id,
                                                    page: _currentPage,
                                                    folderService:
                                                        widget.folderService,
                                                  ),
                                            ),
                                          ).then(
                                            (_) => setState(() {
                                              _isSelectionMode = false;
                                              _selectedItemIds.clear();
                                            }),
                                          );
                                        } else if (type == 'pdf') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EditPdfPage(
                                                folderService:
                                                    widget.folderService,
                                                pdf: file,
                                              ),
                                            ),
                                          ).then(
                                            (_) => setState(() {
                                              _isSelectionMode = false;
                                              _selectedItemIds.clear();
                                            }),
                                          );
                                        } else if (type == 'folder') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditFolderPage(
                                                    folderService:
                                                        widget.folderService,
                                                    folder: file,
                                                  ),
                                            ),
                                          ).then(
                                            (_) => setState(() {
                                              _isSelectionMode = false;
                                              _selectedItemIds.clear();
                                            }),
                                          );
                                        }
                                        break;
                                      case "delete":
                                        for (final id in _selectedItemIds) {
                                          widget.folderService.deleteItem(id);
                                        }
                                        setState(() {
                                          _isSelectionMode = false;
                                          _selectedItemIds.clear();
                                        });
                                        break;
                                      case "move":
                                        // setState(() {
                                        //   _isMovingMode = true;
                                        //   _isSelectionMode = false;
                                        // });
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            fullscreenDialog: true,
                                            builder: (context) => MoveModePage(
                                              folderService:
                                                  widget.folderService,
                                              selectedItemIds: _selectedItemIds,
                                              initialFolderId: widget.folder.id,
                                            ),
                                          ),
                                        ).then((done) {
                                          if (done != null && done) {
                                            debugPrint('testA');
                                            setState(() {
                                              _isSelectionMode = false;
                                              _selectedItemIds.clear();
                                              _isMovingMode = false;
                                            });
                                          }
                                        });
                                        break;
                                    }
                                  },
                                ),
                        ],
                      )
                    : Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              _previousPage = _currentPage;
                              navigateToPage(_currentPage - 1);
                            },
                            icon: const Icon(Icons.keyboard_arrow_left),
                          ),
                          Text("Page $_currentPage"),
                          IconButton(
                            onPressed: () {
                              _previousPage = _currentPage;
                              navigateToPage(_currentPage + 1);
                            },
                            icon: const Icon(Icons.keyboard_arrow_right),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                desktopView = !desktopView;
                                _settingsService.setDesktopView(desktopView);
                              });
                            },
                            icon: const Icon(Icons.abc),
                          ),
                        ],
                      ),
              ],
            ),
            body: _buildUI(
              screenWidth,
              screenHeight,
              appBarHeight,
              statusBarHeight,
            ),
            floatingActionButton: PopupMenuButton<FileTypeCustom>(
              onSelected: (value) {
                switch (value) {
                  case FileTypeCustom.folder:
                    _createFolder();
                    break;
                  case FileTypeCustom.note:
                    _createNote();
                    break;
                  case FileTypeCustom.pdf:
                    _createPdf();
                    break;
                  case FileTypeCustom.audio:
                    _createAudioFile();
                    break;
                  case FileTypeCustom.canvas:
                    _createCanvas();
                    break;
                  case FileTypeCustom.quiz:
                    _createQuiz();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: FileTypeCustom.folder,
                  child: Row(
                    children: [
                      const Icon(Icons.folder),
                      const SizedBox(width: 8),
                      const Text("Add Folder"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: FileTypeCustom.note,
                  child: Row(
                    children: [
                      const Icon(Icons.note),
                      const SizedBox(width: 8),
                      const Text("Create Note"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: FileTypeCustom.pdf,
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf),
                      const SizedBox(width: 8),
                      const Text("Create Pdf"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: FileTypeCustom.audio,
                  child: Row(
                    children: [
                      const Icon(Icons.audio_file),
                      const SizedBox(width: 8),
                      const Text("Create Audio File"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: FileTypeCustom.canvas,
                  child: Row(
                    children: [
                      const Icon(Icons.audio_file),
                      const SizedBox(width: 8),
                      const Text("Add a drawing (test)"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: FileTypeCustom.quiz,
                  child: Row(
                    children: [
                      const Icon(Icons.quiz),
                      const SizedBox(width: 8),
                      const Text("Create a Quiz"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: FileTypeCustom.canvas,
                  child: Row(
                    children: [
                      const Icon(Icons.color_lens),
                      const SizedBox(width: 8),
                      const Text("Create Drawing"),
                    ],
                  ),
                ),
              ],
              child: FloatingActionButton(
                onPressed: null,
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ),

        // Bottom options bar when panning
        // if (_isDragging)
        // Positioned(
        //   left: 0,
        //   right: 0,
        //   bottom: 0,
        //   child: AnimatedSwitcher(
        //     duration: const Duration(milliseconds: 100),
        //     transitionBuilder: (child, animation) {
        //       return SlideTransition(
        //         position: Tween<Offset>(
        //           begin: Offset(0.0, 1.0),
        //           end: Offset(0, 0),
        //         ).animate(animation),
        //         child: child,
        //       );
        //     },
        //     child: (_isDragging)
        //         ? Opacity(
        //             opacity: (_isOverDeleteArea) ? 1 : 0.7,
        //             child: Material(
        //               key: _deleteAreaKey,
        //               type: MaterialType.transparency,
        //               child: Container(
        //                 key: ValueKey<bool>(_isDragging),
        //                 width: 100,
        //                 height: 70,
        //                 // color: Colors.black,
        //                 decoration: BoxDecoration(
        //                   color: Colors.black,
        //                   borderRadius: BorderRadius.circular(10),
        //                 ),
        //                 alignment: Alignment.bottomCenter,
        //                 margin: const EdgeInsets.only(bottom: 20),
        //                 child: Column(
        //                   mainAxisAlignment: MainAxisAlignment.center,
        //                   children: [
        //                     AnimatedContainer(
        //                       duration: const Duration(milliseconds: 100),
        //                       // transitionBuilder: (child, animation) {
        //                       //   return FadeTransition(
        //                       //     opacity: animation,
        //                       //     child: child,
        //                       //   );
        //                       // },
        //                       child: (_isOverDeleteArea)
        //                           ? Icon(
        //                               Icons.delete_forever,
        //                               key: ValueKey('active'),
        //                               size: 40,
        //                               color: Colors.red,
        //                             )
        //                           : Icon(
        //                               Icons.delete,
        //                               key: ValueKey('inactive'),
        //                               size: 40,
        //                               color: Colors.red,
        //                             ),
        //                     ),
        //                     const Text(
        //                       "Delete",
        //                       style: TextStyle(fontSize: 18, color: Colors.red),
        //                     ),
        //                   ],
        //                 ),
        //               ),
        //             ),
        //           )
        //         : SizedBox.shrink(),
        //   ),
        // ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Material(
                type: MaterialType.transparency,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Loading...",
                        style: TextStyle(fontSize: 24, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          _isCanceled = true;
                          setState(() {
                            _isLoading = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _toggleSelectAll() {
    setState(() {
      if (_areAllSelected) {
        _selectedItemIds.clear();
        _areAllSelected = false;
      } else {
        for (final item in widget.folderService.getFilesInFolder(
          widget.folder.id,
        )) {
          _selectedItemIds.add(item['file'].id);
          _areAllSelected = true;
        }
      }
    });
  }

  void _createFolder() {
    showDialog(
      context: context,
      builder: (context) {
        String folderName = "";
        String folderDescription = "";
        return AlertDialog(
          title: Text("Create New Folder"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: "Folder Name"),
                onChanged: (value) {
                  folderName = value;
                },
              ),
              TextField(
                decoration: InputDecoration(
                  labelText: "Description (optional)",
                ),
                onChanged: (value) {
                  folderDescription = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final Map<String, dynamic> freePositionResult = widget
                    .folderService
                    .getNextFreePosition(false, widget.folder.id, _currentPage);
                final Offset position = freePositionResult['position'];
                if (freePositionResult['page'] == -1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Page is full"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                if (folderName.trim().isNotEmpty) {
                  widget.folderService.createFolder(
                    folderName.trim(),
                    description: folderDescription.trim().isEmpty
                        ? null
                        : folderDescription.trim(),
                    folderId: widget.folder.id,
                    positionX: position.dx,
                    positionY: position.dy,
                    page: _currentPage,
                    pages: 1,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: Text("Create"),
            ),
          ],
        );
      },
    );
  }

  void _createNote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateNotePage(
          folderId: widget.folder.id,
          page: (desktopView ? -1 : _currentPage),
          folderService: widget.folderService,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _createPdf() async {
    _isCanceled = false;
    setState(() {
      _isLoading = true;
    });

    final FilePicker picker = FilePicker.platform;

    final FilePickerResult? result = await picker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) {
      setState(() {
        _isLoading = false;
      });
    }
    for (final pickedFile in result!.files) {
      final String id = '${DateTime.now().millisecondsSinceEpoch}.pdf';
      final directory = await getApplicationDocumentsDirectory();
      final String destinationPath = p.join(directory.path, id);
      final File file = await File(pickedFile.path!).copy(destinationPath);
      final sourceFilePath = pickedFile.path!;
      final permanentFilePath = file.path;
      // await Future.delayed(Duration(milliseconds: 1800));
      if (_isCanceled) {
        debugPrint("Cancelled");
        if (await File(sourceFilePath).exists()) {
          await File(sourceFilePath).delete();
        }
        if (await File(permanentFilePath).exists()) {
          await File(permanentFilePath).delete();
        }
        setState(() {
          _isLoading = false;
        });
        break;
      }
      if (mounted) {
        String pdfName = pickedFile.name;
        pdfName = pdfName.substring(0, pdfName.length - 4);
        final Map<String, dynamic> freePositionResult = widget.folderService
            .getNextFreePosition(false, widget.folder.id, _currentPage);
        final Offset position = freePositionResult['position'];
        if (freePositionResult['page'] == -1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Page is full"),
              behavior: SnackBarBehavior.floating,
            ),
          );
          if (await File(sourceFilePath).exists()) {
            await File(sourceFilePath).delete();
          }
          if (await File(permanentFilePath).exists()) {
            await File(permanentFilePath).delete();
          }
          setState(() {
            _isLoading = false;
          });
          break;
        }
        if (pdfName.trim().isNotEmpty) {
          setState(() {
            _isLoading = true;
          });
          try {
            widget.folderService.createPdf(
              title: pdfName,
              filePath: file.path,
              folderId: widget.folder.id,
              positionX: position.dx,
              positionY: position.dy,
              page: _currentPage,
            );
          } catch (e) {
            try {
              if (await File(sourceFilePath).exists()) {
                await File(sourceFilePath).delete();
              }
              if (await File(permanentFilePath).exists()) {
                await File(permanentFilePath).delete();
              }
            } catch (e) {
              debugPrint('Warning: Could not delete cache file');
            }
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Something went wrong")));
          } finally {
            try {
              if (await File(sourceFilePath).exists()) {
                await File(sourceFilePath).delete();
              }
            } catch (e) {
              debugPrint('Warning: Could not delete cache file: $e');
            }
          }
        }
        if (await File(sourceFilePath).exists()) {
          await File(sourceFilePath).delete();
        }
        continue;
      }
      if (await File(sourceFilePath).exists()) {
        await File(sourceFilePath).delete();
      }
      if (await File(permanentFilePath).exists()) {
        await File(permanentFilePath).delete();
      }
    }

    setState(() {
      _isLoading = false;
    });
    // if (mounted) {
    //   setState(() {
    //     _isLoading = false;
    //   });
    // } else {
    //   try {
    //     if (await File(sourceFilePath).exists()) {
    //       await File(sourceFilePath).delete();
    //     }
    //     if (await File(permanentFilePath).exists()) {
    //       await File(permanentFilePath).delete();
    //     }
    //   } catch (e) {
    //     debugPrint('Warning: Could not delete cache file: $e');
    //   }
    // }

    // if (result.files.isNotEmpty && mounted && !_isCanceled) {
    //   try {
    //     if (await File(sourceFilePath).exists()) {
    //       await File(sourceFilePath).delete();
    //     }
    //   } catch (e) {
    //     debugPrint('Warning: Could not delete cache file: $e');
    //   }
    //   showDialog(
    //     context: context,
    //     builder: (context) {
    //       String pdfName = "";
    //       return AlertDialog(
    //         title: Text("Create Pdf"),
    //         content: Column(
    //           mainAxisSize: MainAxisSize.min,
    //           children: [
    //             TextField(
    //               decoration: InputDecoration(labelText: "Pdf Name"),
    //               onChanged: (value) {
    //                 pdfName = value;
    //               },
    //             ),
    //           ],
    //         ),
    //         actions: [
    //           TextButton(
    //             onPressed: () async {
    //               try {
    //                 if (await File(sourceFilePath).exists()) {
    //                   await File(sourceFilePath).delete();
    //                 }
    //                 if (await File(permanentFilePath).exists()) {
    //                   await File(permanentFilePath).delete();
    //                 }
    //               } catch (e) {
    //                 debugPrint('Warning: Could not delete cache file: $e');
    //               }
    //               Navigator.of(context).pop();
    //             },
    //             child: Text("Cancel"),
    //           ),
    //           ElevatedButton(
    //             onPressed: () async {
    //               final Map<String, dynamic> freePositionResult = widget
    //                   .folderService
    //                   .getNextFreePosition(
    //                     false,
    //                     widget.folder.id,
    //                     _currentPage,
    //                   );
    //               final Offset position = freePositionResult['position'];
    //               if (freePositionResult['page'] == -1) {
    //                 ScaffoldMessenger.of(context).showSnackBar(
    //                   SnackBar(
    //                     content: Text("Page is full"),
    //                     behavior: SnackBarBehavior.floating,
    //                   ),
    //                 );
    //                 return;
    //               }
    //               if (pdfName.trim().isNotEmpty) {
    //                 setState(() {
    //                   _isLoading = true;
    //                 });
    //                 try {
    //                   widget.folderService.createPdf(
    //                     title: pdfName,
    //                     filePath: file.path,
    //                     folderId: widget.folder.id,
    //                     positionX: position.dx,
    //                     positionY: position.dy,
    //                     page: _currentPage,
    //                   );
    //                 } catch (e) {
    //                   try {
    //                     if (await File(sourceFilePath).exists()) {
    //                       await File(sourceFilePath).delete();
    //                     }
    //                     if (await File(permanentFilePath).exists()) {
    //                       await File(permanentFilePath).delete();
    //                     }
    //                   } catch (e) {
    //                     debugPrint('Warning: Could not delete cache file: $e');
    //                   }
    //                   ScaffoldMessenger.of(context).showSnackBar(
    //                     SnackBar(content: Text("Something went wrong")),
    //                   );
    //                 } finally {
    //                   try {
    //                     if (await File(sourceFilePath).exists()) {
    //                       await File(sourceFilePath).delete();
    //                     }
    //                   } catch (e) {
    //                     debugPrint('Warning: Could not delete cache file: $e');
    //                   }
    //                   if (mounted) {
    //                     setState(() {
    //                       _isLoading = false;
    //                     });
    //                   }
    //                 }
    //                 // widget.folderService.createFolder(
    //                 //   pdfName.trim(),
    //                 //   description: folderDescription.trim().isEmpty
    //                 //       ? null
    //                 //       : folderDescription.trim(),
    //                 //   folderId: widget.folder.id,
    //                 //   positionX: 0,
    //                 //   positionY: 0,
    //                 // );
    //                 Navigator.of(context).pop();
    //               }
    //             },
    //             child: Text("Create"),
    //           ),
    //         ],
    //       );
    //     },
    //   );
    // } else {
    //   try {
    //     if (await File(sourceFilePath).exists()) {
    //       await File(sourceFilePath).delete();
    //     }
    //     if (await File(permanentFilePath).exists()) {
    //       await File(permanentFilePath).delete();
    //     }
    //   } catch (e) {
    //     debugPrint('Warning: Could not delete cache file: $e');
    //   }
    // }
  }

  void _createAudioFile() async {
    _isCanceled = false;
    setState(() {
      _isLoading = true;
    });
    final FilePicker picker = FilePicker.platform;

    final FilePickerResult? result = await picker.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    final directory = await getApplicationDocumentsDirectory();
    final String destinationPath = p.join(directory.path, id);
    final File file = await File(
      result!.files.first.path!,
    ).copy(destinationPath);
    final sourceFilePath = result.files.first.path!;
    final permanentFilePath = file.path;

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    } else {
      try {
        if (await File(sourceFilePath).exists()) {
          await File(sourceFilePath).delete();
        }
        if (await File(permanentFilePath).exists()) {
          await File(permanentFilePath).delete();
        }
      } catch (e) {
        debugPrint('Warning: Could not delete cache file: $e');
      }
    }

    if (result.files.isNotEmpty && mounted && !_isCanceled) {
      try {
        if (await File(sourceFilePath).exists()) {
          await File(sourceFilePath).delete();
        }
      } catch (e) {
        debugPrint('Warning: Could not delete cache file: $e');
      }
      showDialog(
        context: context,
        builder: (context) {
          String audioName = "";
          return AlertDialog(
            title: Text("Create Audio File"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: "Audio Name"),
                  onChanged: (value) {
                    audioName = value;
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  try {
                    if (await File(sourceFilePath).exists()) {
                      await File(sourceFilePath).delete();
                    }
                    if (await File(permanentFilePath).exists()) {
                      await File(permanentFilePath).delete();
                    }
                  } catch (e) {
                    debugPrint('Warning: Could not delete cache file: $e');
                  }
                  Navigator.of(context).pop();
                },
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final Map<String, dynamic> freePositionResult = widget
                      .folderService
                      .getNextFreePosition(
                        false,
                        widget.folder.id,
                        _currentPage,
                      );
                  final Offset position = freePositionResult['position'];
                  if (freePositionResult['page'] == -1) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Page is full"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  if (audioName.trim().isNotEmpty) {
                    setState(() {
                      _isLoading = true;
                    });
                    try {
                      widget.folderService.createAudio(
                        title: audioName,
                        filePath: file.path,
                        folderId: widget.folder.id,
                        positionX: position.dx,
                        positionY: position.dy,
                        page: _currentPage,
                      );
                    } catch (e) {
                      try {
                        if (await File(sourceFilePath).exists()) {
                          await File(sourceFilePath).delete();
                        }
                        if (await File(permanentFilePath).exists()) {
                          await File(permanentFilePath).delete();
                        }
                      } catch (e) {
                        debugPrint('Warning: Could not delete cache file: $e');
                      }
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Something went wrong")),
                      );
                    } finally {
                      try {
                        if (await File(sourceFilePath).exists()) {
                          await File(sourceFilePath).delete();
                        }
                      } catch (e) {
                        debugPrint('Warning: Could not delete cache file: $e');
                      }
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                    Navigator.of(context).pop();
                  }
                },
                child: Text("Create"),
              ),
            ],
          );
        },
      );
    } else {
      try {
        if (await File(sourceFilePath).exists()) {
          await File(sourceFilePath).delete();
        }
        if (await File(permanentFilePath).exists()) {
          await File(permanentFilePath).delete();
        }
      } catch (e) {
        debugPrint('Warning: Could not delete cache file: $e');
      }
    }
  }

  // void _createCanvas() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (context) => CanvasPage()),
  //   );
  // }

  void _createQuiz() {
    final Map<String, dynamic> freePositionResult = widget.folderService
        .getNextFreePosition(false, widget.folder.id, _currentPage);
    final Offset position = freePositionResult['position'];
    if (freePositionResult['page'] == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Page is full"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    String quizId = widget.folderService.createQuiz(
      title: "Untitled Quiz",
      folderId: widget.folder.id,
      positionX: position.dx,
      positionY: position.dy,
      options: [],
      page: _currentPage,
    );
    widget.folderService.createQuizQuestion(
      title: "Question Name",
      quizId: quizId,
      answers: ['Answer 1', 'Answer 2', 'Answer 3', 'Answer 4'],
      correctAnswers: ['Answer 1'],
      filePaths: [],
      type: QuizQuestionType.mcq1.name,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateQuizPage(
          quizId: quizId,
          folderService: widget.folderService,
          folder: widget.folder,
        ),
      ),
    );
  }

  void _createCanvas() {
    final Map<String, dynamic> freePositionResult = widget.folderService
        .getNextFreePosition(false, widget.folder.id, _currentPage);
    final Offset position = freePositionResult['position'];
    if (freePositionResult['page'] == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Page is full"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    String canvasId = widget.folderService.createCanvas(
      name: "Untitled Drawing",
      folderId: widget.folder.id,
      positionX: position.dx,
      positionY: position.dy,
      page: _currentPage,
      strokes: [],
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CanvasPage(canvasId: canvasId, folderService: widget.folderService),
      ),
    );
  }

  void navigateToPage(int pageNumber) {
    if (pageNumber < 1 || pageNumber > 4) return;

    setState(() {
      _currentPage = pageNumber;
    });
  }

  Widget _buildUI(
    double screenWidth,
    double screenHeight,
    double appBarHeight,
    double statusBarHeight,
  ) {
    final filesListenable = (desktopView)
        ? widget.folderService.getFilesInFolderListener(
            widget.folder.id,
            page: _currentPage,
          )
        : widget.folderService.getFilesInFolderListener(widget.folder.id);
    // if (desktopView) {
    //   filesListenable = widget.folderService.getFilesInFolderListener(
    //     widget.folder.id,
    //     page: _currentPage,
    //   );
    // } else {
    //   filesListenable = widget.folderService.getFilesInFolderListener(
    //     widget.folder.id,
    //   );
    // }

    return (desktopView)
        ? _buildDesktopView(
            screenWidth,
            screenHeight,
            appBarHeight,
            statusBarHeight,
            filesListenable,
          )
        : _buildNormalView(filesListenable);
  }

  Widget _buildNormalView(
    ValueListenable<List<Map<String, dynamic>>> filesListenable,
  ) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: filesListenable,
      builder: (context, files, child) {
        return GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: files.length,
          itemBuilder: (context, index) {
            files.sort((a, b) {
              final fileA = a['file'];
              final fileB = b['file'];

              final int timeA = fileA.createdAt;
              final int timeB = fileB.createdAt;

              return timeB.compareTo(timeA);
            });
            final isSelected = (_selectedItemIds.any(
              (id) => files[index]['file'].id == id,
            ));
            final String fileTypeCustom = files[index]['type'];

            return GestureDetector(
              onLongPress: () {
                if (!_isSelectionMode) {
                  setState(() {
                    _isSelectionMode = true;
                    _selectedItemIds.add(files[index]['file'].id);
                  });
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.transparent,
                  border: isSelected
                      ? Border.all(color: Colors.blue, width: 3)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: switch (fileTypeCustom) {
                  'folder' => _buildFolderCard(files[index]['file'], context),
                  'note' => _buildNote(files[index]['file'], context),
                  'pdf' => _buildPdfCard(files[index]['file'], context),
                  'quiz' => _buildQuizCard(files[index]['file'], context),
                  'canvas' => _buildCanvasCard(files[index]['file'], context),
                  'audioFile' => _buildAudioFileCard(
                    files[index]['file'],
                    context,
                  ),
                  _ => Container(),
                },
              ),
            );
            // switch (fileTypeCustom) {
            //   case 'folder':
            //     return _buildFolderCard(files[index]['file'], context);
            //   case 'note':
            //     return _buildNote(files[index]['file'], context);
            //   case 'pdf':
            //     return _buildPdfCard(files[index]['file'], context);
            //   case 'audioFile':
            //     return _buildAudioFileCard(files[index]['file'], context);
            // }
          },
        );
      },
    );
  }

  Widget _buildDesktopView(
    double screenWidth,
    double screenHeight,
    double appBarHeight,
    double statusBarHeight,
    ValueListenable<List<Map<String, dynamic>>> filesListenable,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: filesListenable,
          builder: (context, files, child) {
            // for (var item in files) {
            //   desktopItems.add(item);
            // }
            return Container(
              color: Colors.blueGrey,
              child: InteractiveViewer(
                panEnabled: !_isDragging,
                scaleEnabled: !_isDragging,
                transformationController: _transformationController,
                boundaryMargin: EdgeInsets.zero,
                minScale: 0.1,
                maxScale: 5.0,
                onInteractionEnd: (details) {
                  final Matrix4 matrix = _transformationController.value;
                  currentScale = matrix.getMaxScaleOnAxis();
                },
                constrained: false,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 100),
                  child: SizedBox(
                    key: ValueKey<int>(_currentPage),
                    width: desktopWidth,
                    height: desktopHeight,
                    child: Stack(
                      children: [
                        ...itemPreviewHolders.map(
                          (item) => _buildPreviewItemHolder(
                            item['item'],
                            item['dx'],
                            item['dy'],
                            item['mode'],
                          ),
                        ),

                        Positioned(
                          key: ValueKey(
                            "bottom options",
                          ), // had to add this to make the animation work, i have no idea how but it does the trick
                          left:
                              (screenWidth / 2 -
                                      _transformationController.value.entry(
                                        0,
                                        3,
                                      )) /
                                  currentScale -
                              230 / 2,
                          top:
                              (screenHeight -
                                      70 -
                                      20 -
                                      statusBarHeight -
                                      appBarHeight -
                                      _transformationController.value.entry(
                                        1,
                                        3,
                                      )) /
                                  currentScale -
                              (70 - (70 / currentScale)) / 2,
                          child: Transform.scale(
                            scale: 1 / currentScale,
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
                              child: (_isDragging)
                                  ? Opacity(
                                      opacity:
                                          (_isOverDeleteArea ||
                                              _isOverSendToPageArea)
                                          ? 1
                                          : 0.7,
                                      child: Container(
                                        key: ValueKey<bool>(_isDragging),
                                        width: 230,
                                        height: 70,
                                        // color: Colors.black,
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        alignment: Alignment.bottomCenter,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Column(
                                              key: _sendToPageKey,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Stack(
                                                  children: [
                                                    AnimatedSwitcher(
                                                      duration: const Duration(
                                                        milliseconds: 100,
                                                      ),
                                                      child:
                                                          (_isOverSendToPageArea)
                                                          ? Container(
                                                              decoration: BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: Colors
                                                                        .white,
                                                                    blurRadius:
                                                                        40,
                                                                    spreadRadius:
                                                                        1,
                                                                    offset: Offset
                                                                        .zero,
                                                                  ),
                                                                ],
                                                              ),
                                                              child: Icon(
                                                                Icons
                                                                    .arrow_outward,
                                                                key: ValueKey(
                                                                  'active',
                                                                ),
                                                                size: 40,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            )
                                                          : Icon(
                                                              Icons
                                                                  .arrow_outward,
                                                              key: ValueKey(
                                                                'inactive',
                                                              ),
                                                              size: 40,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                    ),
                                                  ],
                                                ),
                                                const Text(
                                                  "Send to page",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 40),
                                            Column(
                                              key: _deleteAreaKey,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Stack(
                                                  children: [
                                                    // Icon(
                                                    //   Icons.delete,
                                                    //   key: ValueKey(
                                                    //     'inactive',
                                                    //   ),
                                                    //   size: 40,
                                                    //   color: Colors.red,
                                                    // ),
                                                    AnimatedSwitcher(
                                                      duration: const Duration(
                                                        milliseconds: 100,
                                                      ),
                                                      child: (_isOverDeleteArea)
                                                          ? Container(
                                                              decoration: BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: Colors
                                                                        .red,
                                                                    blurRadius:
                                                                        40,
                                                                    spreadRadius:
                                                                        1,
                                                                    offset: Offset
                                                                        .zero,
                                                                  ),
                                                                ],
                                                              ),
                                                              child: Icon(
                                                                Icons.delete,
                                                                key: ValueKey(
                                                                  'active',
                                                                ),
                                                                size: 40,
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            )
                                                          : Icon(
                                                              Icons.delete,
                                                              key: ValueKey(
                                                                'inactive',
                                                              ),
                                                              size: 40,
                                                              color: Colors.red,
                                                            ),
                                                    ),
                                                  ],
                                                ),
                                                const Text(
                                                  "Delete",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : SizedBox.shrink(),
                            ),
                          ),
                        ),

                        ...files.map((file) => _buildDesktopItem(file)),
                      ],
                    ),
                  ),
                  transitionBuilder: (child, animation) {
                    Offset beginOffset = Offset(1, 1);

                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: beginOffset,
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    );
                  },
                ),
              ),
            );
          },
        ),

        // ...desktopItems.map((item) => _buildDesktopItem(item))
      ],
    );
  }

  void _showBottomOptions() async {
    final overlay = Overlay.of(context);
    final test = OverlayEntry(
      builder: (context) => Positioned(
        left: 300,
        // right: 0,
        bottom: 20,
        // top: (screenHeight - _transformationController.value.entry(1, 3)) / currentScale - 70 - 90,
        child: Transform.scale(
          scale: 1 / currentScale,
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
            child: (_isDragging)
                ? Material(
                    type: MaterialType.transparency,
                    child: Opacity(
                      key: _deleteAreaKey,
                      opacity: (_isOverDeleteArea) ? 1 : 0.7,
                      child: Container(
                        key: ValueKey<bool>(_isDragging),
                        width: 100,
                        height: 70,
                        // color: Colors.black,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.bottomCenter,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              // transitionBuilder: (child, animation) {
                              //   return FadeTransition(
                              //     opacity: animation,
                              //     child: child,
                              //   );
                              // },
                              child: (_isOverDeleteArea)
                                  ? Icon(
                                      Icons.delete_forever,
                                      key: ValueKey('active'),
                                      size: 40,
                                      color: Colors.red,
                                    )
                                  : Icon(
                                      Icons.delete,
                                      key: ValueKey('inactive'),
                                      size: 40,
                                      color: Colors.red,
                                    ),
                            ),
                            const Text(
                              "Delete",
                              style: TextStyle(fontSize: 18, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SizedBox.shrink(),
          ),
        ),
      ),
    );
    // overlay.insert(test);

    await Future.delayed(Duration(seconds: 5));
    // test.remove();
  }

  Widget _buildPdfCard(Pdf pdf, BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          if (_isSelectionMode && (!_isMovingMode || widget.isMovingMode)) {
            setState(() {
              if (_selectedItemIds.any(((id) => pdf.id == id))) {
                _selectedItemIds.remove(pdf.id);
                if (_selectedItemIds.isEmpty) {
                  _isSelectionMode = false;
                }
              } else {
                _selectedItemIds.add(pdf.id);
              }
            });
          } else if (_isMovingMode || widget.isMovingMode) {
          } else {
            _openDocument(pdf.filePath);
          }
        },
        // onLongPress: () {
        //   showBottomSheet(context, pdf, 'pdf');
        // },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.folder, size: 40, color: Colors.green),
              SizedBox(height: 8),
              Text(
                pdf.title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizCard(Quiz quiz, BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          if (_isSelectionMode && (!_isMovingMode || widget.isMovingMode)) {
            setState(() {
              if (_selectedItemIds.any(((id) => quiz.id == id))) {
                _selectedItemIds.remove(quiz.id);
                if (_selectedItemIds.isEmpty) {
                  _isSelectionMode = false;
                }
              } else {
                _selectedItemIds.add(quiz.id);
              }
            });
          } else if (_isMovingMode || widget.isMovingMode) {
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateQuizPage(
                  quizId: quiz.id,
                  folderService: widget.folderService,
                  folder: widget.folder,
                ),
              ),
            );
          }
        },
        // onLongPress: () {
        //   _showBottomSheet(context, pdf, 'pdf');
        // },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.quiz, size: 40, color: Colors.green),
              SizedBox(height: 8),
              Text(
                quiz.title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCanvasCard(Canvas canvas, BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          if (_isSelectionMode && (!_isMovingMode || widget.isMovingMode)) {
            setState(() {
              if (_selectedItemIds.any(((id) => canvas.id == id))) {
                _selectedItemIds.remove(canvas.id);
                if (_selectedItemIds.isEmpty) {
                  _isSelectionMode = false;
                }
              } else {
                _selectedItemIds.add(canvas.id);
              }
            });
          } else if (_isMovingMode || widget.isMovingMode) {
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CanvasPage(
                  canvasId: canvas.id,
                  folderService: widget.folderService,
                ),
              ),
            );
          }
        },
        // onLongPress: () {
        //   _showBottomSheet(context, pdf, 'pdf');
        // },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.color_lens, size: 40, color: Colors.pink),
              SizedBox(height: 8),
              Text(
                canvas.name,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioFileCard(AudioFile audio, BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          if (_isSelectionMode && (!_isMovingMode || widget.isMovingMode)) {
            setState(() {
              if (_selectedItemIds.any(((id) => audio.id == id))) {
                _selectedItemIds.remove(audio.id);
                if (_selectedItemIds.isEmpty) {
                  _isSelectionMode = false;
                }
              } else {
                _selectedItemIds.add(audio.id);
              }
            });
          } else if (_isMovingMode || widget.isMovingMode) {
          } else {
            _openAudio(audio.filePath);
          }
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => FolderPage(
          //       folder: pdf,
          //       folderService: widget.folderService,
          //     ),
          //   ),
          // );
        },
        // onLongPress: () {
        //   _showBottomSheet(context, audio, 'audio');
        // },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.audio_file, size: 40, color: Colors.yellow),
              SizedBox(height: 8),
              Text(
                audio.title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolderCard(Folder folder, BuildContext context) {
    return Card(
      child: Opacity(
        opacity: (widget.selectedItemIds.any((id) => id == folder.id))
            ? 0.7
            : 1,
        child: InkWell(
          onTap: () {
            if (widget.selectedItemIds.any((id) => id == folder.id)) return;
            // if(widget.initialFolder == folder) return;
            if (_isSelectionMode) {
              setState(() {
                if (_selectedItemIds.any(((id) => folder.id == id))) {
                  _selectedItemIds.remove(folder.id);
                  if (_selectedItemIds.isEmpty) {
                    _isSelectionMode = false;
                  }
                } else {
                  _selectedItemIds.add(folder.id);
                }
              });
            } else if (widget.isMovingMode) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FolderPage(
                    folder: folder,
                    folderService: widget.folderService,
                    isMovingMode: true,
                    selectedItemIds: widget.selectedItemIds,
                    onCancel: widget.onCancel,
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FolderPage(
                    folder: folder,
                    folderService: widget.folderService,
                    isMovingMode: false,
                    selectedItemIds: {},
                  ),
                ),
              ).then((_) => setState(() {}));
            }
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(builder: (context) => DesktopView(
            //     notes: widget.folderService.getNotesInFolder(folder.id),
            //   )),
            // );
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.folder, size: 40, color: Colors.blue),
                SizedBox(height: 8),
                Text(
                  folder.name,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                if (folder.description != null) ...[
                  SizedBox(height: 4),
                  Text(
                    folder.description!,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNote(Note note, BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          if (_isSelectionMode && (!_isMovingMode || widget.isMovingMode)) {
            setState(() {
              if (_selectedItemIds.any(((id) => note.id == id))) {
                _selectedItemIds.remove(note.id);
                if (_selectedItemIds.isEmpty) {
                  _isSelectionMode = false;
                }
              } else {
                _selectedItemIds.add(note.id);
              }
            });
          } else if (_isMovingMode || widget.isMovingMode) {
          } else {
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => CreateNotePage(
            //       noteId: note.id,
            //       folderId: note.folderId,
            //       page: _currentPage,
            //       folderService: widget.folderService,
            //     ),
            //   ),
            // ).then((_) => setState(() {}));
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewNotePage(
                  noteId: note.id,
                  folderId: note.folderId,
                  page: _currentPage,
                  folderService: widget.folderService,
                ),
              ),
            ).then((_) => setState(() {}));
          }
        },
        // onLongPress: () {
        //   _showBottomSheet(context, note, 'note');
        // },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                note.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(Note note, BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: () {
          // Navigate to edit note page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateNotePage(
                noteId: note.id,
                folderId: note.folderId,
                page: _currentPage,
                folderService: widget.folderService,
              ),
            ),
          ).then((_) => setState(() {}));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                note.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 8),

              // Content preview
              if (note.document.isNotEmpty) _buildContentPreview(note.document),

              // Images count
              if (note.movableElements.isNotEmpty)
                _buildMediaIndicator(note.movableElements),

              SizedBox(height: 8),

              // Footer with date and tags
              _buildNoteFooter(note),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentPreview(List<Map<String, dynamic>> document) {
    // Extract plain text from Quill document for preview
    String previewText = '';

    for (var op in document) {
      if (op['insert'] is String) {
        previewText += op['insert'];
      }
    }

    // Clean up and limit preview length
    previewText = previewText.trim();
    if (previewText.length > 150) {
      previewText = previewText.substring(0, 150) + '...';
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        previewText,
        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildMediaIndicator(List<MovableElementData> movableElements) {
    final imageCount = movableElements
        .where((e) => e.type == ElementType.image)
        .length;
    final audioCount = movableElements
        .where((e) => e.type == ElementType.audio)
        .length;
    final docCount = movableElements
        .where((e) => e.type == ElementType.document)
        .length;

    return Row(
      children: [
        if (imageCount > 0)
          Row(
            children: [
              Icon(Icons.image, size: 16, color: Colors.green),
              SizedBox(width: 4),
              Text('$imageCount', style: TextStyle(fontSize: 12)),
              SizedBox(width: 12),
            ],
          ),

        if (audioCount > 0)
          Row(
            children: [
              Icon(Icons.audiotrack, size: 16, color: Colors.orange),
              SizedBox(width: 4),
              Text('$audioCount', style: TextStyle(fontSize: 12)),
              SizedBox(width: 12),
            ],
          ),

        if (docCount > 0)
          Row(
            children: [
              Icon(Icons.insert_drive_file, size: 16, color: Colors.blue),
              SizedBox(width: 4),
              Text('$docCount', style: TextStyle(fontSize: 12)),
            ],
          ),
      ],
    );
  }

  Widget _buildNoteFooter(Note note) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Tags
        if (note.tags.isNotEmpty)
          Wrap(
            spacing: 4,
            children: note.tags.take(2).map((tag) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tag,
                  style: TextStyle(fontSize: 10, color: Colors.blue[800]),
                ),
              );
            }).toList(),
          ),

        // Date
        Text(
          _formatDate(note.updatedAt),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // void _showCreateFolderDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => CreateFolderDialog(folderService: folderService),
  //   );
  // }

  Widget _buildDesktopItem(Map<String, dynamic> file) {
    final type = file['type'];
    final item = file['file'];
    final items = widget.folderService.getFilesInFolderPage(
      widget.folder.id,
      _currentPage,
    );
    String fileName = "Undefined";
    late IconData icon;

    switch (type) {
      case 'folder':
        fileName = (item as Folder).name;
        icon = Icons.folder;
        break;
      case 'note':
        fileName = (item as Note).title;
        icon = Icons.note;
        break;
      case 'pdf':
        fileName = (item as Pdf).title;
        icon = Icons.picture_as_pdf;
        break;
      case 'audioFile':
        fileName = (item as AudioFile).title;
        icon = Icons.audio_file;
        break;
      case 'quiz':
        fileName = (item as Quiz).title;
        icon = Icons.quiz;
        break;
      case 'canvas':
        fileName = (item as Canvas).name;
        icon = Icons.color_lens;
        break;
    }

    return Positioned(
      left: item.positionX,
      top: item.positionY,
      key: ValueKey(item.id),
      child: GestureDetector(
        onLongPressStart: (details) {
          _startOffset = Offset(item.positionX, item.positionY);
          _startGlobalOffset = details.globalPosition / currentScale;
          itemPreviewHolders.add({
            'item': file,
            'dx': item.positionX,
            'dy': item.positionY,
            'mode': 'preview',
          });
          itemPreviewHolders.add({
            'item': file,
            'dx': item.positionX,
            'dy': item.positionY,
            'mode': 'old_position',
          });
          setState(() {
            _isDragging = true;
          });
        },
        onLongPressMoveUpdate: (details) {
          final Offset totalDelta =
              (details.globalPosition / currentScale - _startGlobalOffset);
          final bool isOverDeleteArea = _isDraggedOverDeleteArea(
            details.globalPosition,
          );
          final bool isOverSendToPageArea = _isDraggedOverSendToPageArea(
            details.globalPosition,
          );
          setState(() {
            final finalOffset = _startOffset + totalDelta;
            final previewPositionX =
                (finalOffset.dx.clamp(0, 2000 - 200) / grid).roundToDouble() *
                grid;
            final previewPositionY =
                (finalOffset.dy.clamp(0, 2000 - 200) / grid).roundToDouble() *
                grid;

            bool positionTaken = false;
            for (final entry in items) {
              final FileBase file = entry['file'] as FileBase;
              if (file.id == item.id) continue;

              if ((file.positionX - previewPositionX).abs() < 200 &&
                  (file.positionY - previewPositionY).abs() < 200) {
                positionTaken = true;
                break;
              }
            }
            if (positionTaken) {
            } else {
              itemPreviewHolders[0]['dx'] = previewPositionX;
              itemPreviewHolders[0]['dy'] = previewPositionY;
            }

            item.positionX = (finalOffset.dx.clamp(0, 2000 - 200)) + 0.0;
            item.positionY = (finalOffset.dy.clamp(0, 2000 - 200)) + 0.0;
            _isOverDeleteArea = isOverDeleteArea;
            _isOverSendToPageArea = isOverSendToPageArea;
          });
        },
        onLongPressEnd: (details) {
          if (_isOverDeleteArea) {
            setState(() {
              widget.folderService.deleteItem(item.id);
              _isDragging = false;
              itemPreviewHolders.clear();
            });
            return;
          }
          setState(() {
            _isDragging = false;
            itemPreviewHolders.clear();
            final notes = widget.folderService.getNotesInFolderPage(
              widget.folder.id,
              _currentPage,
            );
            final folders = widget.folderService.getFoldersInFolderPage(
              widget.folder.id,
              _currentPage,
            );
            final pdfs = widget.folderService.getPdfsInFolderPage(
              widget.folder.id,
              _currentPage,
            );
            final audios = widget.folderService.getAudioFilesInFolderPage(
              widget.folder.id,
              _currentPage,
            );
            final canvases = widget.folderService.getCanvasesInFolderPage(
              widget.folder.id,
              _currentPage,
            );

            final Offset totalDelta =
                (details.globalPosition / currentScale - _startGlobalOffset);
            final finalOffset = _startOffset + totalDelta;
            final positionX =
                (finalOffset.dx.clamp(0, 2000 - 200) / grid).roundToDouble() *
                grid;
            final positionY =
                (finalOffset.dy.clamp(0, 2000 - 200) / grid).roundToDouble() *
                grid;
            bool positionTaken = false;
            for (final item in items) {
              final FileBase file = item['file'] as FileBase;

              if (file.positionX == positionX && file.positionY == positionY) {
                positionTaken = true;
              }
            }
            // for (final note in notes) {
            //   if (note.positionX == positionX && note.positionY == positionY) {
            //     positionTaken = true;
            //   }
            // }
            // for (final pdf in pdfs) {
            //   if (pdf.positionX == positionX && pdf.positionY == positionY) {
            //     positionTaken = true;
            //   }
            // }
            // for (final folder in folders) {
            //   if (folder.positionX == positionX &&
            //       folder.positionY == positionY) {
            //     positionTaken = true;
            //   }
            // }
            // for (final audio in audios) {
            //   if (audio.positionX == positionX &&
            //       audio.positionY == positionY) {
            //     positionTaken = true;
            //   }
            // }
            if (!positionTaken) {
              item.positionX =
                  (finalOffset.dx.clamp(0, 2000 - 200) / grid).roundToDouble() *
                  grid;
              item.positionY =
                  (finalOffset.dy.clamp(0, 2000 - 200) / grid).roundToDouble() *
                  grid;
            } else {
              item.positionX = _startOffset.dx;
              item.positionY = _startOffset.dy;
            }
          });
          switch (type) {
            case 'folder':
              widget.folderService.updateFolder(item);
              break;
            case 'note':
              widget.folderService.updateNote(item);
              break;
            case 'pdf':
              widget.folderService.updatePdf(item);
              break;
            case 'audioFile':
              widget.folderService.updateAudio(item);
              break;
            case 'quiz':
              widget.folderService.updateQuiz(item);
              break;
            case 'canvas':
              widget.folderService.updateCanvas(item);
              break;
          }
        },
        onTap: () {
          switch (type) {
            case 'folder':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FolderPage(
                    folder: item,
                    folderService: widget.folderService,
                    isMovingMode: false,
                    selectedItemIds: {},
                  ),
                ),
              ).then((_) => setState(() {}));
              break;
            case 'note':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateNotePage(
                    noteId: item.id,
                    folderId: item.folderId,
                    page: _currentPage,
                    folderService: widget.folderService,
                  ),
                ),
              ).then((_) => setState(() {}));
              break;
            case 'canvas':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CanvasPage(
                    canvasId: item.id,
                    folderService: widget.folderService,
                  ),
                ),
              ).then((_) => setState(() {}));
              break;
            case 'quiz':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateQuizPage(
                    quizId: item.id,
                    folderService: widget.folderService,
                    folder: widget.folder,
                  ),
                ),
              );
              break;
            case 'pdf':
              _openDocument(item.filePath);
              break;
            case 'audioFile':
              break;
          }
        },
        child: Container(
          width: 200,
          height: 200,
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.blue, size: 100),
              Text(
                fileName,
                style: TextStyle(fontSize: 20),
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewItemHolder(
    Map<String, dynamic> file,
    double positionX,
    double positionY,
    String mode,
  ) {
    final type = file['type'];
    final item = file['file'];
    String fileName = "Undefined";
    late IconData icon;

    switch (type) {
      case 'folder':
        fileName = (item as Folder).name;
        icon = Icons.folder;
        break;
      case 'note':
        fileName = (item as Note).title;
        icon = Icons.note;
        break;
      case 'pdf':
        fileName = (item as Pdf).title;
        icon = Icons.picture_as_pdf;
        break;
      case 'audioFile':
        fileName = (item as AudioFile).title;
        icon = Icons.audio_file;
        break;
      case 'quiz':
        fileName = (item as Quiz).title;
        icon = Icons.quiz;
        break;
      case 'canvas':
        fileName = (item as Canvas).name;
        icon = Icons.color_lens;
        break;
    }

    return Positioned(
      left: positionX,
      top: positionY,
      child: Opacity(
        opacity: 0.4,
        child: Container(
          width: 200,
          height: 200,
          // color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.blue, size: 100),
              Text(
                fileName,
                style: TextStyle(fontSize: 20),
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSwipe(DragEndDetails details) {
    if (details.primaryVelocity! > 0) {
      // left
      debugPrint("this is a test");
    } else if (details.primaryVelocity! < 0) {
      debugPrint("this is a different test");
      //right
    }
  }

  bool _isDraggedOverDeleteArea(Offset draggedItemCenter) {
    final RenderBox? renderBox =
        _deleteAreaKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return false;

    final Offset position = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    final Rect deleteAreaRect = position & size;

    return deleteAreaRect.contains(draggedItemCenter);
  }

  bool _isDraggedOverSendToPageArea(Offset draggedItemCenter) {
    final RenderBox? renderBox =
        _sendToPageKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return false;

    final Offset position = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    final Rect sendToPageAreaRect = position & size;

    return sendToPageAreaRect.contains(draggedItemCenter);
  }

  void _openAudio(String filePath) async {
    try {
      final result = await OpenFile.open(filePath, type: 'audio/x-mpeg');

      if (!mounted) return;
      switch (result.type) {
        case ResultType.done:
          break;
        case ResultType.noAppToOpen:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Found no apps that can open that file')),
          );
          break;
        case ResultType.fileNotFound:
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('File not found')));
          break;
        case ResultType.permissionDenied:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Permission denied to open file')),
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
      ).showSnackBar(SnackBar(content: Text('Failed to open file: $e')));
    }
  }

  void _openDocument(String filePath) async {
    try {
      final result = await OpenFile.open(filePath, type: 'application/pdf');

      if (!mounted) return;
      switch (result.type) {
        case ResultType.done:
          break;
        case ResultType.noAppToOpen:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Found no apps that can open that file')),
          );
          break;
        case ResultType.fileNotFound:
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('File not found')));
          break;
        case ResultType.permissionDenied:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Permission denied to open file')),
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
      ).showSnackBar(SnackBar(content: Text('Failed to open file: $e')));
    }
  }

  void _showBottomSheet(BuildContext context, dynamic item, String type) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    switch (type) {
                      case 'note':
                        widget.folderService.deleteNote(item.id);
                        break;
                      case 'pdf':
                        widget.folderService.deletePdf(item.id);
                        break;
                      case 'audio':
                        widget.folderService.deleteAudioFile(item.id);
                        break;
                      case 'folder':
                        widget.folderService.deleteFolder(item.id);
                        break;
                    }
                    Navigator.pop(context);
                  },
                  child: const Row(
                    children: [
                      SizedBox(width: 10),

                      Icon(Icons.delete, color: Colors.red),

                      Text(
                        "Delete",
                        style: TextStyle(fontSize: 28, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _clearSelection() {
    setState(() {
      _selectedItemIds.clear();
      _isSelectionMode = false;
    });
  }
}
