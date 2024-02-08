import 'dart:ui';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:flame/components.dart';

class ColoredSquare extends AgentVisualization {
  ColoredSquare(Vector2 position, [this.color = const Color(0xFF000000)])
      : super(
          anchor: Anchor.topLeft,
          position: position,
          size: Vector2.all(kGameConfiguration.world.tileSize),
        );

  factory ColoredSquare.red(Vector2 position) => ColoredSquare(
        position,
        const Color(0xFFFF0000),
      );

  factory ColoredSquare.green(Vector2 position) => ColoredSquare(
        position,
        const Color(0xFF00FF00),
      );

  factory ColoredSquare.blue(Vector2 position) => ColoredSquare(
        position,
        const Color(0xFF0000FF),
      );

  final Color color;

  @override
  void onLoad() {
    add(
      RectangleComponent(
        paint: Paint()
          ..color = color
          ..isAntiAlias = false,
        size: size,
      ),
    );
  }
}
