import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyfold/models/audio_file.dart';
import 'package:studyfold/models/canvas_element.dart';
import 'package:studyfold/models/file.dart';
import 'package:studyfold/models/file_base.dart';
import 'package:studyfold/models/folder.dart';
import 'package:studyfold/models/movable_element.dart';
import 'package:studyfold/models/movable_element_data.dart';
import 'package:studyfold/models/note.dart';
import 'package:studyfold/models/pdf.dart';
import 'package:studyfold/models/quiz.dart';
import 'package:studyfold/models/quiz_question.dart';
import 'package:studyfold/models/canvas.dart';
import 'package:studyfold/models/hive_stroke.dart';
import 'package:uuid/uuid.dart';

class FolderService {
  final Box<Folder> folderBox;
  final Box<Note> noteBox;
  final Box<AudioFile> audioFileBox;
  final Box<Pdf> pdfBox;
  final Box<Quiz> quizBox;
  final Box<QuizQuestion> quizQuestionBox;
  final Box<Canvas> canvasBox;
  final Box<HiveStroke> strokesBox;
  final Box<HiveFile> filesBox;
  final Box<MovableElementData> movableElementsBox;

  FolderService(
    this.folderBox,
    this.noteBox,
    this.audioFileBox,
    this.pdfBox,
    this.quizBox,
    this.quizQuestionBox,
    this.canvasBox,
    this.strokesBox,
    this.filesBox,
    this.movableElementsBox,
  );

  void createMovableElement({required MovableElement movableElement}) {
    final movableElementData = movableElement.toData();
    movableElementsBox.put(movableElementData.id, movableElementData);
  }

  void createFile({required String parentId, required String filePath}) async {
    final file = HiveFile(
      id: const Uuid().v4(),
      parentId: parentId,
      filepath: filePath,
    );
    await filesBox.put(file.id, file);
  }

  void deleteFile({required String parentId}) async {
    final HiveFile fileToDelete = filesBox.values.firstWhere(
      (file) => file.parentId == parentId,
    );

    await filesBox.delete(fileToDelete.id);

    if (filesBox.values
        .where((file) => file.filepath == fileToDelete.filepath)
        .isEmpty) {
      if (await File(fileToDelete.filepath).exists()) {
        await File(fileToDelete.filepath).delete();
      }
    }
  }

  void createFolder(
    String name, {
    String? description,
    required String folderId,
    required double positionX,
    required double positionY,
    required int page,
    required int pages,
  }) {
    final folder = Folder(
      id: const Uuid().v4(),
      name: name,
      folderId: folderId,
      description: description,
      positionX: positionX,
      positionY: positionY,
      page: page,
      pages: pages,
    );
    folderBox.put(folder.id, folder);
  }

  void createPdf({
    required String title,
    required String filePath,
    required String folderId,
    required double positionX,
    required double positionY,
    required int page,
  }) {
    final pdf = Pdf(
      id: const Uuid().v4(),
      folderId: folderId,
      title: title,
      filePath: filePath,
      positionX: positionX,
      positionY: positionY,
      page: page,
    );
    createFile(parentId: pdf.id, filePath: filePath);
    pdfBox.put(pdf.id, pdf);
  }

  void createAudio({
    required String title,
    required String filePath,
    required String folderId,
    required double positionX,
    required double positionY,
    required int page,
  }) {
    final audio = AudioFile(
      id: const Uuid().v4(),
      folderId: folderId,
      title: title,
      filePath: filePath,
      positionX: positionX,
      positionY: positionY,
      page: page,
    );
    createFile(parentId: audio.id, filePath: filePath);
    audioFileBox.put(audio.id, audio);
  }

  Future<String> createCanvas({
    required String name,
    required String folderId,
    required double positionX,
    required double positionY,
    required int page,
    required List<HiveStroke> strokes,
  }) async {
    final canvas = Canvas(
      id: const Uuid().v4(),
      folderId: folderId,
      name: name,
      positionX: positionX,
      positionY: positionY,
      page: page,
      strokes: strokes,
    );
    await canvasBox.put(canvas.id, canvas);
    return canvas.id;
  }

  List<Folder> getAllFolders() {
    return folderBox.values.toList();
  }

  void createNote({
    required String folderId,
    required List<Map<String, dynamic>> document,
    required List<MovableElementData> movableElements,
    required double positionX,
    required double positionY,
    required int page,
    String title = 'Untitled Note',
  }) {
    final note = Note(
      id: const Uuid().v4(),
      folderId: folderId,
      title: title,
      document: document,
      positionX: positionX,
      positionY: positionY,
      page: page,
      movableElements: movableElements,
    );
    noteBox.put(note.id, note);
  }

  String createQuiz({
    required String title,
    required String folderId,
    required double positionX,
    required double positionY,
    required int page,
    required List<String> options,
  }) {
    final quiz = Quiz(
      id: const Uuid().v4(),
      folderId: folderId,
      options: options,
      page: page,
      positionX: positionX,
      positionY: positionY,
      title: title,
    );
    quizBox.put(quiz.id, quiz);
    return quiz.id;
  }

  void createQuizQuestion({
    required String title,
    required String quizId,
    required List<String> answers,
    required List<String> correctAnswers,
    required List<String> filePaths,
    required String type,
  }) {
    final quizQuestion = QuizQuestion(
      id: const Uuid().v4(),
      title: title,
      parentQuizId: quizId,
      answers: answers,
      correctAnswers: correctAnswers,
      filePaths: filePaths,
      type: type,
    );
    quizQuestionBox.put(quizQuestion.id, quizQuestion);
  }

  List<QuizQuestion> getQuestionsInQuiz({required String quizId}) {
    return quizQuestionBox.values
        .where((question) => question.parentQuizId == quizId)
        .toList();
  }

  List<Note> getNotesInFolder(String folderId) {
    return noteBox.values.where((note) => note.folderId == folderId).toList();
  }

  List<Canvas> getCanvasesInFolder(String folderId) {
    return canvasBox.values
        .where((canvas) => canvas.folderId == folderId)
        .toList();
  }

  List<Note> getNotesInFolderPage(String folderId, int page) {
    return noteBox.values
        .where((note) => note.folderId == folderId && note.page == page)
        .toList();
  }

  List<Pdf> getPdfsInFolder(String folderId) {
    return pdfBox.values.where((pdf) => pdf.folderId == folderId).toList();
  }

  List<Pdf> getPdfsInFolderPage(String folderId, int page) {
    return pdfBox.values
        .where((pdf) => pdf.folderId == folderId && pdf.page == page)
        .toList();
  }

  List<Quiz> getQuizzesInFolderPage(String folderId, int page) {
    return quizBox.values
        .where((pdf) => pdf.folderId == folderId && pdf.page == page)
        .toList();
  }

  List<Canvas> getCanvasesInFolderPage(String folderId, int page) {
    return canvasBox.values
        .where((canvas) => canvas.folderId == folderId && canvas.page == page)
        .toList();
  }

  List<AudioFile> getAudioFilesInFolder(String folderId) {
    return audioFileBox.values
        .where((audioFile) => audioFile.folderId == folderId)
        .toList();
  }

  List<Quiz> getQuizzesInFolder(String folderId) {
    return quizBox.values.where((quiz) => quiz.folderId == folderId).toList();
  }

  List<AudioFile> getAudioFilesInFolderPage(String folderId, int page) {
    return audioFileBox.values
        .where(
          (audioFile) =>
              audioFile.folderId == folderId && audioFile.page == page,
        )
        .toList();
  }

  List<Folder> getFoldersInFolder(String folderId) {
    return folderBox.values
        .where((folder) => folder.folderId == folderId)
        .toList();
  }

  List<Folder> getFoldersInFolderPage(String folderId, int page) {
    return folderBox.values
        .where((folder) => folder.folderId == folderId && folder.page == page)
        .toList();
  }

  List<FileBase> gatherFolderContents(String folderId) {
    List<FileBase> contents = [];

    final folder = folderBox.get(folderId);
    if (folder == null) {
      return [getItemById(folderId)['file']];
    }
    contents.add(folder);

    final children = tempGetFilesInFolder(folderId);
    contents.addAll(children);

    for (var child in children) {
      if (child is Folder) {
        contents.addAll(gatherFolderContents(child.id));
      }
    }

    return contents.toSet().toList();
  }

  ValueListenable<List<Map<String, dynamic>>> getFilesInFolderListener(
    String folderId, {
    int? page,
  }) {
    final ValueNotifier<List<Map<String, dynamic>>> fileListNotifier =
        (page == null)
        ? ValueNotifier(getFilesInFolder(folderId))
        : ValueNotifier(getFilesInFolderPage(folderId, page));

    void listener() {
      if (page == null) {
        fileListNotifier.value = getFilesInFolder(folderId);
      } else {
        fileListNotifier.value = getFilesInFolderPage(folderId, page);
      }
    }

    noteBox.listenable().addListener(listener);
    folderBox.listenable().addListener(listener);
    pdfBox.listenable().addListener(listener);
    audioFileBox.listenable().addListener(listener);
    quizBox.listenable().addListener(listener);
    canvasBox.listenable().addListener(listener);

    return fileListNotifier;
  }

  List<FileBase> tempGetFilesInFolder(String folderId) {
    final List<FileBase> contents = [];

    noteBox.values.where((note) => note.folderId == folderId).forEach((note) {
      contents.add(note);
    });

    canvasBox.values.where((canvas) => canvas.folderId == folderId).forEach((
      canvas,
    ) {
      contents.add(canvas);
    });

    folderBox.values.where((folder) => folder.folderId == folderId).forEach((
      folder,
    ) {
      contents.add(folder);
    });

    pdfBox.values.where((pdf) => pdf.folderId == folderId).forEach((pdf) {
      contents.add(pdf);
    });

    quizBox.values.where((quiz) => quiz.folderId == folderId).forEach((quiz) {
      contents.add(quiz);
    });

    audioFileBox.values
        .where((audioFile) => audioFile.folderId == folderId)
        .forEach((audioFile) {
          contents.add(audioFile);
        });

    return contents;
  }

  List<Map<String, dynamic>> getFilesInFolder(String folderId) {
    final List<Map<String, dynamic>> files = [];

    noteBox.values.where((note) => note.folderId == folderId).forEach((note) {
      files.add({'type': 'note', 'file': note});
    });

    canvasBox.values.where((canvas) => canvas.folderId == folderId).forEach((
      canvas,
    ) {
      files.add({'type': 'canvas', 'file': canvas});
    });

    folderBox.values.where((folder) => folder.folderId == folderId).forEach((
      folder,
    ) {
      files.add({'type': 'folder', 'file': folder});
    });

    pdfBox.values.where((pdf) => pdf.folderId == folderId).forEach((pdf) {
      files.add({'type': 'pdf', 'file': pdf});
    });

    quizBox.values.where((quiz) => quiz.folderId == folderId).forEach((quiz) {
      files.add({'type': 'quiz', 'file': quiz});
    });

    audioFileBox.values
        .where((audioFile) => audioFile.folderId == folderId)
        .forEach((audioFile) {
          files.add({'type': 'audioFile', 'file': audioFile});
        });

    return files;
  }

  List<Map<String, dynamic>> getFilesInFolderPage(String folderId, int page) {
    final List<Map<String, dynamic>> files = [];

    noteBox.values
        .where((note) => note.folderId == folderId && note.page == page)
        .forEach((note) {
          files.add({'type': 'note', 'file': note});
        });

    canvasBox.values
        .where((canvas) => canvas.folderId == folderId && canvas.page == page)
        .forEach((canvas) {
          files.add({'type': 'canvas', 'file': canvas});
        });

    folderBox.values
        .where((folder) => folder.folderId == folderId && folder.page == page)
        .forEach((folder) {
          files.add({'type': 'folder', 'file': folder});
        });

    pdfBox.values
        .where((pdf) => pdf.folderId == folderId && pdf.page == page)
        .forEach((pdf) {
          files.add({'type': 'pdf', 'file': pdf});
        });

    quizBox.values
        .where((quiz) => quiz.folderId == folderId && quiz.page == page)
        .forEach((quiz) {
          files.add({'type': 'quiz', 'file': quiz});
        });

    audioFileBox.values
        .where(
          (audioFile) =>
              audioFile.folderId == folderId && audioFile.page == page,
        )
        .forEach((audioFile) {
          files.add({'type': 'audioFile', 'file': audioFile});
        });

    return files;
  }

  void updateNote(Note note) {
    noteBox.put(note.id, note);
  }

  void updateCanvas(Canvas canvas) {
    canvasBox.put(canvas.id, canvas);
  }

  void updateCanvasElementChildren(
    String canvasId,
    CanvasElement updatedElement,
  ) {
    final Canvas canvas = canvasBox.get(canvasId)!;
    final index = canvas.elements.indexWhere(
      (element) =>
          element.movableElement != null &&
          element.movableElement!.id == updatedElement.movableElement!.id,
    );
    if (index != -1) {
      canvas.elements[index] = updatedElement;
    }
    canvasBox.put(canvas.id, canvas);
  }

  void updateCanvasElements(String canvasId, List<CanvasElement> elements) {
    final Canvas canvas = canvasBox.get(canvasId)!;
    canvas.elements = elements;
    canvasBox.put(canvas.id, canvas);
  }

  void updateCanvasStrokes(String canvasId, List<HiveStroke> strokes) {
    final Canvas canvas = canvasBox.get(canvasId)!;
    canvas.strokes = strokes;
    canvasBox.put(canvas.id, canvas);
  }

  void updateCanvasImages(String canvasId, List<MovableElementData> images) {
    final Canvas canvas = canvasBox.get(canvasId)!;
    canvas.images = images;
    canvasBox.put(canvas.id, canvas);
  }

  void updateCanvasDocuments(
    String canvasId,
    List<MovableElementData> documents,
  ) {
    final Canvas canvas = canvasBox.get(canvasId)!;
    canvas.documents = documents;
    canvasBox.put(canvas.id, canvas);
  }

  List<CanvasElement> getCanvasElements(String canvasId) {
    final Canvas canvas = canvasBox.get(canvasId)!;
    return canvas.elements.toList();
  }

  //temp TODO
  List<HiveStroke> getCanvasStrokes(String canvasId) {
    final Canvas canvas = canvasBox.get(canvasId)!;
    return canvas.strokes;
  }

  void updateFolder(Folder folder) {
    folderBox.put(folder.id, folder);
  }

  void updatePdf(Pdf pdf) {
    pdfBox.put(pdf.id, pdf);
  }

  void updateQuiz(Quiz quiz) {
    quizBox.put(quiz.id, quiz);
  }

  void updateAudio(AudioFile audio) {
    audioFileBox.put(audio.id, audio);
  }

  void updateQuizQuestionTitle(String newTitle, QuizQuestion question) {
    question.title = newTitle;
    quizQuestionBox.put(question.id, question);
  }

  void deleteNote(String noteId) async {
    final note = noteBox.get(noteId);
    for (final element in note!.movableElements) {
      if (await File(element.filePath).exists()) {
        await File(element.filePath).delete();
      }
    }
    noteBox.delete(noteId);
  }

  void deleteQuizQuestion(String id) async {
    quizQuestionBox.delete(id);
  }

  void deleteCanvas(String id) async {
    canvasBox.delete(id);
  }

  void deletePdf(String pdfId) async {
    deleteFile(parentId: pdfId);

    pdfBox.delete(pdfId);
  }

  void deleteQuiz(String quizId) async {
    // final quiz = quizBox.get(quizId);
    quizBox.delete(quizId);

    //todo
  }

  void deleteAudioFile(String audioFileId) async {
    final audio = audioFileBox.get(audioFileId);
    final filePath = audio!.filePath;
    if (await File(filePath).exists()) {
      await File(filePath).delete();
    }
    audioFileBox.delete(audioFileId);
  }

  Future<void> deleteFolder(String folderId) async {
    final folderNotes = getNotesInFolder(folderId);
    final folderPdfs = getPdfsInFolder(folderId);
    final folderCanvases = getCanvasesInFolder(folderId);
    final folderQuizzes = getQuizzesInFolder(folderId);
    final folderAudioFiles = getAudioFilesInFolder(folderId);
    for (final note in folderNotes) {
      for (final element in note.movableElements) {
        if (await File(element.filePath).exists()) {
          await File(element.filePath).delete();
        }
      }
      noteBox.delete(note.id);
    }
    for (final pdf in folderPdfs) {
      if (await File(pdf.filePath).exists()) {
        await File(pdf.filePath).delete();
      }
      pdfBox.delete(pdf.id);
    }
    for (final canvas in folderCanvases) {
      canvasBox.delete(canvas.id);
    }
    for (final quiz in folderQuizzes) {
      quizBox.delete(quiz.id);
    }
    for (final audio in folderAudioFiles) {
      if (await File(audio.filePath).exists()) {
        await File(audio.filePath).delete();
      }
      audioFileBox.delete(audio.id);
    }
    folderBox.delete(folderId);
  }

  Map<String, dynamic> getNextFreePosition(
    bool searchOtherPages,
    String folderId,
    int currentPage,
  ) {
    Map<String, dynamic> result = {'position': Offset(-1, -1), 'page': -1};
    final List<FileBase> items = [];

    final desktopItems = getFilesInFolderPage(folderId, currentPage);

    for (final item in desktopItems) {
      items.add(item['file'] as FileBase);
    }

    for (
      int page = currentPage;
      page < (searchOtherPages ? 99 : currentPage + 1);
      page++
    ) {
      for (int j = 0; j < 1999; j = j + 200) {
        for (int i = 0; i < 1999; i = i + 200) {
          if (!items.any(
            (item) => item.positionX == i && item.positionY == j,
          )) {
            result['position'] = Offset(i.toDouble(), j.toDouble());
            result['page'] = page;
            return result;
          }
        }
      }
    }

    return result;
  }

  Map<String, dynamic> getItemById(String id) {
    late dynamic item;
    late String type;
    if (noteBox.get(id) != null) {
      item = noteBox.get(id) as Note;
      type = "note";
    } else if (audioFileBox.get(id) != null) {
      item = audioFileBox.get(id) as AudioFile;
      type = "audio";
    } else if (pdfBox.get(id) != null) {
      item = pdfBox.get(id) as Pdf;
      type = "pdf";
    } else if (folderBox.get(id) != null) {
      item = folderBox.get(id) as Folder;
      type = "folder";
    } else if (quizBox.get(id) != null) {
      item = quizBox.get(id) as Quiz;
      type = "quiz";
    } else if (canvasBox.get(id) != null) {
      item = canvasBox.get(id) as Canvas;
      type = "canvas";
    }
    return {'type': type, 'file': item};
  }

  void moveItem(String itemId, String folderId, int page) {
    final freePosition = getNextFreePosition(true, folderId, page);
    final Offset position = freePosition['position'];
    final int newPage = freePosition['page'];
    if (noteBox.get(itemId) != null) {
      final note = noteBox.get(itemId);
      note!.folderId = folderId;
      note.positionX = position.dx;
      note.positionY = position.dy;
      note.page = newPage;
      updateNote(note);
    } else if (audioFileBox.get(itemId) != null) {
      final audio = audioFileBox.get(itemId);
      audio!.folderId = folderId;
      audio.positionX = position.dx;
      audio.positionY = position.dy;
      audio.page = newPage;
      updateAudio(audio);
    } else if (pdfBox.get(itemId) != null) {
      final pdf = pdfBox.get(itemId);
      pdf!.folderId = folderId;
      pdf.positionX = position.dx;
      pdf.positionY = position.dy;
      pdf.page = newPage;
      updatePdf(pdf);
    } else if (folderBox.get(itemId) != null) {
      final folder = folderBox.get(itemId);
      folder!.folderId = folderId;
      folder.positionX = position.dx;
      folder.positionY = position.dy;
      folder.page = newPage;
      updateFolder(folder);
    } else if (quizBox.get(itemId) != null) {
      final quiz = quizBox.get(itemId);
      quiz!.folderId = folderId;
      quiz.positionX = position.dx;
      quiz.positionY = position.dy;
      quiz.page = newPage;
      updateQuiz(quiz);
    } else if (canvasBox.get(itemId) != null) {
      final canvas = canvasBox.get(itemId);
      canvas!.folderId = folderId;
      canvas.positionX = position.dx;
      canvas.positionY = position.dy;
      canvas.page = newPage;
      updateCanvas(canvas);
    }
  }

  void deleteItem(String itemId) async {
    final item = getItemById(itemId);
    final type = item['type'];
    final file = item['file'];
    switch (type) {
      case 'note':
        final note = file as Note;
        for (final element in note.movableElements) {
          if (await File(element.filePath).exists()) {
            await File(element.filePath).delete();
          }
        }
        noteBox.delete(itemId);
        break;
      case 'folder':
        final folderNotes = getNotesInFolder(itemId);
        final folderPdfs = getPdfsInFolder(itemId);
        final folderAudioFiles = getAudioFilesInFolder(itemId);
        for (final note in folderNotes) {
          for (final element in note.movableElements) {
            if (await File(element.filePath).exists()) {
              await File(element.filePath).delete();
            }
          }
          noteBox.delete(note.id);
        }
        for (final pdf in folderPdfs) {
          deletePdf(pdf.id);
        }
        for (final audio in folderAudioFiles) {
          if (await File(audio.filePath).exists()) {
            await File(audio.filePath).delete();
          }
          audioFileBox.delete(audio.id);
        }
        folderBox.delete(itemId);
        break;
      case 'pdf':
        deletePdf(file.id);
        break;
      case 'quiz':
        // final quiz = file as Quiz;
        quizBox.delete(itemId);
        break;
      case 'canvas':
        canvasBox.delete(itemId);
        break;
      case 'audio':
        final audio = file as AudioFile;
        final filePath = audio.filePath;
        if (await File(filePath).exists()) {
          await File(filePath).delete();
        }
        audioFileBox.delete(itemId);
        break;
    }
  }
}
