import 'package:hive/hive.dart';

part 'stroke_type.g.dart';

@HiveType(typeId: 12)
enum StrokeType {
  @HiveField(0)
  pen,
  
  @HiveField(1)
  highlighter,
  
  @HiveField(2)
  dashed,
}