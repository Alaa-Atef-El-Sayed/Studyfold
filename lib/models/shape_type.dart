import 'package:hive/hive.dart';

part 'shape_type.g.dart';

@HiveType(typeId: 15)
enum ShapeType {
  @HiveField(0)
  rectangle,
  
  @HiveField(1)
  circle,
  
  @HiveField(2)
  triangle,
  
  @HiveField(3)
  line,
}