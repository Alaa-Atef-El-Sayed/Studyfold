import 'package:flutter/material.dart';
import 'package:studyfold/models/folder.dart';
import 'package:studyfold/models/quiz.dart';
import 'package:studyfold/models/quiz_question.dart';
import 'package:studyfold/services/folder_service.dart';

enum QuizQuestionType { mcq1, mcq2, written }

class CreateQuizPage extends StatefulWidget {
  final String quizId;
  final FolderService folderService;
  final Folder folder;
  const CreateQuizPage({
    super.key,
    required this.quizId,
    required this.folderService,
    required this.folder,
  });

  @override
  State<CreateQuizPage> createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  late TextEditingController _questionNameController;
  late List<QuizQuestion> questions;
  late final Quiz quiz;
  int _currentIndex = 0;
  String? selectedAnswer;

  @override
  void initState() {
    quiz = widget.folderService.getItemById(widget.quizId)['file'];
    questions = widget.folderService.getQuestionsInQuiz(quizId: widget.quizId);
    _questionNameController = TextEditingController(
      text: questions[_currentIndex].title,
    );
    super.initState();
  }

  @override
  void dispose() {
    _questionNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: _buildUI(),
      endDrawer: Drawer(
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Container(
                padding: EdgeInsets.all(4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _buildInfoTile("Options", Icons.settings),
                        _buildInfoTile("Scores", Icons.star),
                      ],
                    ),
                    Row(
                      children: [
                        _buildInfoTile("Score Calculation", Icons.bar_chart),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Questions",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: Colors.blueAccent,
                      size: 28,
                    ),
                    onPressed: () {
                      _addQuestion();
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(150, 0, 0, 0),
                      ),
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: questions.map((question) {
                          return ListTile(
                            enableFeedback: false,
                            title: Text(
                              question.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              onPressed: () {
                                _openQuestionSettings();
                              },
                              icon: const Icon(Icons.settings),
                            ),
                            onTap: () {
                              _editQuestion(question);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Expanded(
            //   child: Padding(
            //     padding: const EdgeInsets.all(12),
            //     child: Container(
            //       decoration: BoxDecoration(
            //         color: const Color.fromARGB(80, 0, 0, 0),
            //         borderRadius: BorderRadius.circular(12),
            //       ),
            //       child: SingleChildScrollView(
            //         child: Column(
            //           children: [
            //             ...questions.map(
            //               (question) => ListTile(
            //                 title: Text(question.title),
            //                 trailing: IconButton(
            //                   onPressed: () {
            //                     _openQuestionSettings();
            //                   },
            //                   icon: const Icon(Icons.settings),
            //                 ),
            //                 onTap: () {
            //                   _editQuestion(question);
            //                 },
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildUI() {
    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                questions[_currentIndex].title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ]),
        ),

        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            children: [
              const Spacer(),
              Padding(
                padding: EdgeInsets.all(16),
                child: switch (questions[_currentIndex].type) {
                  'mcq1' => _buildMcq1Answers(),
                  _ => Container(),
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMcq1Answers() {
    return Column(
      children: [
        ...questions[_currentIndex].answers.map(
          (answer) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          (questions[_currentIndex].correctAnswers.contains(
                            answer,
                          ))
                          ? const Color.fromARGB(160, 76, 175, 79)
                          : const Color.fromARGB(160, 244, 67, 54),
                    ),
                  ),
                  child: RadioListTile(
                    title: Text(answer),
                    value: answer,
                    activeColor:
                        (questions[_currentIndex].correctAnswers.contains(
                          answer,
                        ))
                        ? const Color.fromARGB(160, 76, 175, 79)
                        : const Color.fromARGB(160, 244, 67, 54),
                    groupValue: selectedAnswer,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    secondary: IconButton(
                      onPressed: () {
                        _showMcq1AnswerOptions(answer);
                      },
                      icon: const Icon(Icons.settings),
                    ),
                    // tileColor:
                    //     (questions[_currentIndex].correctAnswers.contains(answer))
                    //     ? const Color.fromARGB(160, 76, 175, 79)
                    //     : const Color.fromARGB(160, 244, 67, 54),
                    onChanged: (value) {
                      setState(() {
                        selectedAnswer = value;
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueAccent),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.add, color: Colors.blueAccent),
              title: const Text(
                "Add Answer",
                style: TextStyle(color: Colors.blueAccent),
              ),
              onTap: () {
                String newAnswerTitle = "";
                String? errorText;
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return StatefulBuilder(
                      builder: (context, setDialogState) => AlertDialog(
                        title: const Text("Add Answer"),
                        content: SizedBox(
                          width: 240,
                          child: TextFormField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Answer Title",
                              errorText: errorText,
                            ),
                            onChanged: (value) => newAnswerTitle = value,
                            autofocus: true,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              if (questions[_currentIndex].answers.contains(
                                newAnswerTitle,
                              )) {
                                setDialogState(() {
                                  errorText = "This answer already exists";
                                });
                              } else {
                                setState(() {
                                  questions[_currentIndex].answers.add(
                                    newAnswerTitle,
                                  );

                                  Navigator.pop(context);
                                });
                              }
                            },
                            child: const Text("Done"),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showMcq1AnswerOptions(String answer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          title: Text("Choice Options"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check),
                title: const Text("Set right choice"),
                onTap: () {
                  setState(() {
                    questions[_currentIndex].correctAnswers = [answer];
                    widget.folderService.updateQuiz(quiz);
                  });
                },
              ),

              const SizedBox(height: 10),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text("Delete", style: TextStyle(color: Colors.red)),
                onTap: () {
                  setState(() {
                    questions[_currentIndex].answers.remove(answer);
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Done"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoTile(String title, IconData icon) {
    // Keep Expanded here so they share the WIDTH equally (50/50 split)
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blueAccent)),
        color: const Color.fromARGB(75, 0, 0, 0),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            // 💡 Use Padding to give content breathing room instead of fixed height
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 8.0,
            ),
            child: Column(
              children: [
                Icon(icon, color: Colors.blueAccent, size: 28),
                SizedBox(height: 8), // Gap
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center, // Center text if it wraps
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addQuestion() {
    setState(() {
      widget.folderService.createQuizQuestion(
        title: "Question Name",
        quizId: quiz.id,
        answers: ['Answer 1', 'Answer 2', 'Answer 3', 'Answer 4'],
        correctAnswers: ['Answer 1'],
        filePaths: [],
        type: QuizQuestionType.mcq1.name,
      );
      questions = widget.folderService.getQuestionsInQuiz(
        quizId: widget.quizId,
      );
    });
  }

  void _editQuestion(QuizQuestion question) {
    setState(() {
      _currentIndex = questions.indexOf(question);
      Navigator.pop(context);
    });
  }

  void _openQuestionSettings() {
    bool editNameEnabled = false;
    _questionNameController.text = questions[_currentIndex].title;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text("Options"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: Text("Delete", style: TextStyle(color: Colors.red)),
                    onTap: () {
                      setState(() {
                        widget.folderService.deleteQuizQuestion(
                          questions[_currentIndex].id,
                        );
                        questions = widget.folderService.getQuestionsInQuiz(
                          quizId: widget.quizId,
                        );
                        Navigator.pop(context);
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: SizedBox(
                          width: 240,
                          child: TextFormField(
                            enabled: editNameEnabled,
                            controller: _questionNameController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Question Title",
                            ),
                            onFieldSubmitted: (value) {},
                            autofocus: true,
                          ),
                        ),
                      ),

                      IconButton(
                        icon: Icon(
                          editNameEnabled ? Icons.check : Icons.edit,
                          color: editNameEnabled ? Colors.green : Colors.grey,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            setState(() {
                              widget.folderService.updateQuizQuestionTitle(
                                _questionNameController.text,
                                questions[_currentIndex],
                              );
                              questions = widget.folderService
                                  .getQuestionsInQuiz(quizId: widget.quizId);
                            });
                            editNameEnabled = !editNameEnabled;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Done"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
