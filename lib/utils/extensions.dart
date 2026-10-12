import 'dart:ui';

import 'package:flame/game.dart';
import 'package:json_annotation/json_annotation.dart';

extension RectExtension on Rect {
  bool containsVector2(Vector2 vector) {
    // Adjust the condition to include the right and bottom edges
    return vector.x >= left && vector.x <= right && vector.y >= top && vector.y <= bottom;
  }

  bool containsNotVector2(Vector2 vector) {
    // Adjust the condition to include the right and bottom edges
    return !(vector.x >= left && vector.x <= right && vector.y >= top && vector.y <= bottom);
  }
}

extension Vector2Serialization on Vector2 {
  // Convert a Vector2 to a Map<String, dynamic> for JSON serialization
  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  // Create a Vector2 from a Map<String, dynamic>. This function is static
  // because it's used to instantiate a Vector2 from JSON, so it doesn't
  // operate on an instance of Vector2.
  static Vector2 fromJson(Map<String, dynamic> json) {
    return Vector2(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
    );
  }
}

// Define the converter

class Vector2Converter implements JsonConverter<Vector2, Map<String, dynamic>> {
  const Vector2Converter();

  @override
  Vector2 fromJson(Map<String, dynamic> json) {
    return Vector2(json['x'] as double, json['y'] as double);
  }

  @override
  Map<String, dynamic> toJson(Vector2 vector) => {'x': vector.x, 'y': vector.y};
}
