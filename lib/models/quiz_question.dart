import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:studyfold/models/file_base.dart';
import 'package:studyfold/models/movable_element_data.dart';
part 'quiz_question.g.dart';

@HiveType(typeId: 8)
class QuizQuestion{
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
    required this.correctAnswers
  }) : createdAt = DateTime.now().millisecondsSinceEpoch, 
       updatedAt = DateTime.now().millisecondsSinceEpoch;
}