import 'dart:ui';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/representation/world_view.dart';
import 'package:flame/components.dart';

class ColoredSquare extends AgentVisualization {
  ColoredSquare(
      {required super.position, this.color = const Color(0xFF000000), required super.agent})
      : super(
          anchor: Anchor.topLeft,
          size: Vector2.all(kGameConfiguration.world.tileSize),
        );

  factory ColoredSquare.red(AgentView agent, Vector2 position) => ColoredSquare(
        agent: agent,
        position: position,
        color: const Color(0xFFFF0000),
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
