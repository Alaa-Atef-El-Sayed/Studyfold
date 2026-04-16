import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:studyfold/models/json_serializable.dart';
import 'package:studyfold/models/shape_type.dart';

part 'shape_config.g.dart';

@HiveType(typeId: 17)
class ShapeConfig implements JsonSerializable {
  @HiveField(0)
  final ShapeType shapeType;

  @HiveField(1)
  final bool drawFromCenter;

  @HiveField(2)
  final bool lockAspectRatio;

  @HiveField(3)
  final double borderRadius;

  @HiveField(4)
  final bool fill;

  @HiveField(5)
  final double borderWidth;

  @HiveField(6)
  final int borderColorValue;

  @HiveField(7)
  final bool isLocked;

  const ShapeConfig({
    this.shapeType = ShapeType.rectangle,
    this.drawFromCenter = false,
    this.lockAspectRatio = false,
    this.borderRadius = 0.0,
    this.fill = true,
    this.borderWidth = 0,
    this.borderColorValue = 0,
    this.isLocked = false,
  });

  ShapeConfig copyWith({
    ShapeType? shapeType,
    bool? drawFromCenter,
    bool? lockAspectRatio,
    double? borderRadius,
    bool? fill,
    double? borderWidth,
    bool? isLocked,
  }) {
    return ShapeConfig(
      shapeType: shapeType ?? this.shapeType,
      drawFromCenter: drawFromCenter ?? this.drawFromCenter,
      lockAspectRatio: lockAspectRatio ?? this.lockAspectRatio,
      fill: fill ?? this.fill,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'shapeType': shapeType.name,
      'drawFromCenter': drawFromCenter,
      'lockAspectRatio': lockAspectRatio,
      'fill': fill,
      'borderRadius': borderRadius,
      'borderWidth': borderWidth,
      'isLocked': isLocked,
    };
  }

  factory ShapeConfig.fromJson(Map<String, dynamic> json) {
    return ShapeConfig(
      shapeType: ShapeType.values.firstWhere(
        (e) => e.name == json['shapeType'],
        orElse: () => ShapeType.rectangle,
      ),
      drawFromCenter: json['drawFromCenter'],
      lockAspectRatio: json['lockAspectRatio'],
      fill: json['fill'],
      borderRadius: json['borderRadius'],
      borderWidth: json['borderWidth'],
      isLocked: json['isLocked'],
    );
  }
}
