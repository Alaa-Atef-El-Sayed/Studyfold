import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:studyfold/home_page.dart';
import 'package:studyfold/models/audio_file.dart';
import 'package:studyfold/models/canvas.dart';
import 'package:studyfold/models/canvas_element.dart';
import 'package:studyfold/models/element_type.dart';
import 'package:studyfold/models/file.dart';
import 'package:studyfold/models/folder.dart';
import 'package:studyfold/models/hive_shape.dart';
import 'package:studyfold/models/hive_stroke.dart';
import 'package:studyfold/models/images.dart';
import 'package:studyfold/models/movable_element.dart';
import 'package:studyfold/models/movable_element_data.dart';
import 'package:studyfold/models/note.dart';
import 'package:studyfold/models/offset_adapter.dart';
import 'package:studyfold/models/pdf.dart';
import 'package:studyfold/models/quiz.dart';
import 'package:studyfold/models/quiz_question.dart';
import 'package:studyfold/models/shape_config.dart';
import 'package:studyfold/models/shape_type.dart';
import 'package:studyfold/models/stroke_type.dart';
import 'package:studyfold/services/folder_service.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:studyfold/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(FolderAdapter());
  Hive.registerAdapter(NoteAdapter());
  Hive.registerAdapter(MovableElementDataAdapter());
  Hive.registerAdapter(ElementTypeAdapter());
  Hive.registerAdapter(AudioFileAdapter());
  Hive.registerAdapter(PdfAdapter());
  Hive.registerAdapter(ImagesAdapter());
  Hive.registerAdapter(QuizAdapter());
  Hive.registerAdapter(QuizQuestionAdapter());
  Hive.registerAdapter(OffsetAdapter());
  Hive.registerAdapter(CanvasAdapter());
  Hive.registerAdapter(HiveStrokeAdapter());
  Hive.registerAdapter(StrokeTypeAdapter());
  Hive.registerAdapter(HiveFileAdapter());
  Hive.registerAdapter(ShapeTypeAdapter());
  Hive.registerAdapter(HiveShapeAdapter());
  Hive.registerAdapter(CanvasElementAdapter());
  Hive.registerAdapter(ShapeConfigAdapter());
  await SettingsService.init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color.fromARGB(255, 24, 24, 24),
        appBarTheme: AppBarTheme(
          color: const Color.fromARGB(100, 0, 0, 0),
          scrolledUnderElevation: 0.0
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.dark,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      home: FutureBuilder<FolderService>(
        future: _initializeApp(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          } else if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            );
          } else {
            final folderService = snapshot.data as FolderService;
            return HomePage(folderService: folderService);
          }
        },
      ),
    );
  }

  Future<FolderService> _initializeApp() async {
    final filesBox = await Hive.openBox<HiveFile>('files');
    await Hive.openBox<Folder>('folders');
    final notesBox = await Hive.openBox<Note>('notes');
    final audioFilesBox = await Hive.openBox<AudioFile>('audio_files');
    final pdfsBox = await Hive.openBox<Pdf>('pdfs');
    final quizzesBox = await Hive.openBox<Quiz>('quizzes');
    final quizQuestionsBox = await Hive.openBox<QuizQuestion>('quiz_questions');
    final canvasesBox = await Hive.openBox<Canvas>('canvases');
    final movableElementsBox = await Hive.openBox<MovableElementData>(
      'movable_elements',
    );
    await Hive.openBox<HiveStroke>('strokes');

    final List<String> validParentIds = [];

    for (var note in notesBox.values) {
      validParentIds.add(note.id);
    }

    for (var movableElement in movableElementsBox.values) {
      validParentIds.add(movableElement.id);
    }

    for (var pdf in pdfsBox.values) {
      validParentIds.add(pdf.id);
    }

    for (var audioFiles in audioFilesBox.values) {
      validParentIds.add(audioFiles.id);
    }

    for (var quiz in quizzesBox.values) {
      validParentIds.add(quiz.id);
    }

    for (var quizQuestion in quizQuestionsBox.values) {
      validParentIds.add(quizQuestion.id);
    }

    for (var canvas in canvasesBox.values) {
      validParentIds.add(canvas.id);
    }

    final keysToDelete = <dynamic>[];

    for (var file in filesBox.values) {
      if (!validParentIds.contains(file.parentId)) {
        final physicalFile = File(file.filepath);
        if (await physicalFile.exists()) {
          await physicalFile.delete();
        }

        keysToDelete.add(file.id);
        debugPrint("Found Zombie File (Crash/Orphan): ${file.filepath}");
      }
    }

    await filesBox.deleteAll(keysToDelete);

    return FolderService(
      Hive.box<Folder>('folders'),
      Hive.box<Note>('notes'),
      Hive.box<AudioFile>('audio_files'),
      Hive.box<Pdf>('pdfs'),
      Hive.box<Quiz>('quizzes'),
      Hive.box<QuizQuestion>('quiz_questions'),
      Hive.box<Canvas>('canvases'),
      Hive.box<HiveStroke>('strokes'),
      Hive.box<HiveFile>('files'),
      Hive.box<MovableElementData>('movable_elements'),
    );
  }

  void runBackgroundCleanup() async {
    compute(_cleanOrphanFiles, null);
  }

  void _cleanOrphanFiles(_) async {
    final filesBox = await Hive.openBox<HiveFile>('files');
    final notesBox = await Hive.openBox<Note>('notes');
    final audioFilesBox = await Hive.openBox<AudioFile>('audio_files');
    final pdfsBox = await Hive.openBox<Pdf>('pdfs');
    final quizzesBox = await Hive.openBox<Quiz>('quizzes');
    final quizQuestionsBox = await Hive.openBox<QuizQuestion>('quiz_questions');
    final canvasesBox = await Hive.openBox<Canvas>('canvases');

    final Set<String> validParentIds = {};

    for (var note in notesBox.values) {
      validParentIds.add(note.id);
    }

    for (var pdf in pdfsBox.values) {
      validParentIds.add(pdf.id);
    }

    for (var audioFiles in audioFilesBox.values) {
      validParentIds.add(audioFiles.id);
    }

    for (var quiz in quizzesBox.values) {
      validParentIds.add(quiz.id);
    }

    for (var quizQuestion in quizQuestionsBox.values) {
      validParentIds.add(quizQuestion.id);
    }

    for (var canvas in canvasesBox.values) {
      validParentIds.add(canvas.id);
    }

    final keysToDelete = <dynamic>[];

    for (var file in filesBox.values) {
      if (!validParentIds.contains(file.parentId)) {
        final physicalFile = File(file.filepath);
        if (await physicalFile.exists()) {
          await physicalFile.delete();
        }

        keysToDelete.add(file.id);
        debugPrint("Found Zombie File (Crash/Orphan): ${file.filepath}");
      }
    }

    await filesBox.deleteAll(keysToDelete);
  }
}
