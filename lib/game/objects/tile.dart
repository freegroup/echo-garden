import 'dart:ui';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';

import 'package:echo_garden/game/game.dart';
import 'package:flame/components.dart';

class TileSquare extends AgentVisualization with HasGameReference<GameVisualization> {
  final Vector2 spritePosition;
  static Vector2 spriteSize = Vector2.all(kGameConfiguration.world.tileSize);
  late final Sprite sprite;

  TileSquare({
    required this.spritePosition,
    super.anchor = Anchor.topLeft,
    required super.position,
  }) : super(
          size: Vector2.all(kGameConfiguration.world.tileSize),
        );

  @override
  void render(Canvas canvas) {
    final paint = Paint()..isAntiAlias = false;
    sprite.render(canvas, size: size, overridePaint: paint);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    sprite = Sprite(
      game.images.fromCache(kGameConfiguration.tileMap.tilemap),
      srcPosition: spritePosition,
      srcSize: spriteSize,
    );

    add(SpriteComponent(sprite: sprite, size: size));
  }
}
