import 'package:hive/hive.dart';

part 'element_type.g.dart';

@HiveType(typeId: 3)
enum ElementType {
  @HiveField(0) image,
  @HiveField(1) audio,
  @HiveField(2) document,
  @HiveField(3) text,
}