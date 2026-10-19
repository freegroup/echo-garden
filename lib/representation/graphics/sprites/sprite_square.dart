import 'dart:ui';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/representation/graphics/sprites/sprite_agent.dart';
import 'package:echo_garden/representation/world_view.dart';
import 'package:flame/components.dart';

class SpriteSquare extends SpriteAgent {
  SpriteSquare(
      {required super.position, this.color = const Color(0xFF000000), required super.agent})
      : super(
          anchor: Anchor.topLeft,
          size: Vector2.all(kGameConfiguration.world.tileSize),
        );

  factory SpriteSquare.red(AgentView agent, Vector2 position) => SpriteSquare(
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
