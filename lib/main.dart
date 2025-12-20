import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:studyfold/home_page.dart';
import 'package:studyfold/models/audio_file.dart';
import 'package:studyfold/models/canvas.dart';
import 'package:studyfold/models/element_type.dart';
import 'package:studyfold/models/folder.dart';
import 'package:studyfold/models/images.dart';
import 'package:studyfold/models/movable_element_data.dart';
import 'package:studyfold/models/note.dart';
import 'package:studyfold/models/pdf.dart';
import 'package:studyfold/models/quiz.dart';
import 'package:studyfold/models/quiz_question.dart';
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
  Hive.registerAdapter(CanvasAdapter());
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
        scaffoldBackgroundColor: Colors.grey[900],
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
    await Hive.openBox<Folder>('folders');
    await Hive.openBox<Note>('notes');
    await Hive.openBox<AudioFile>('audio_files');
    await Hive.openBox<Pdf>('pdfs');
    await Hive.openBox<Quiz>('quizzes');
    await Hive.openBox<QuizQuestion>('quiz_questions');
    await Hive.openBox<Canvas>('canvases');
    return FolderService(Hive.box<Folder>('folders'), Hive.box<Note>('notes'), Hive.box<AudioFile>('audio_files'), Hive.box<Pdf>('pdfs'), Hive.box<Quiz>('quizzes'), Hive.box<QuizQuestion>('quiz_questions'), Hive.box<Canvas>('canvases'));
  }
}
