import 'package:hive/hive.dart';
import 'package:studyfold/models/json_serializable.dart';
part 'quiz_question.g.dart';

@HiveType(typeId: 8)
class QuizQuestion implements JsonSerializable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String parentQuizId;

  @HiveField(2)
  String title;

  @HiveField(3)
  List<String> filePaths;

  @HiveField(4)
  final int createdAt;

  @HiveField(5)
  int updatedAt;

  @HiveField(6)
  String type;

  @HiveField(7)
  List<String> answers;

  @HiveField(8)
  List<String> correctAnswers;

  QuizQuestion({
    required this.id,
    required this.parentQuizId,
    required this.title,
    required this.filePaths,
    required this.type,
    required this.answers,
    required this.correctAnswers,
  }) : createdAt = DateTime.now().millisecondsSinceEpoch,
       updatedAt = DateTime.now().millisecondsSinceEpoch;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
