import 'dart:ui';

import 'package:echo_garden/game/constant.dart';
import 'package:echo_garden/game/game.dart';
import 'package:flame/components.dart';

class TileSquare extends PositionComponent with HasGameReference<EchoGardenGame> {
  final Vector2 spritePosition;
  static Vector2 spriteSize = Vector2.all(tileMapSpriteSize);
  late final Sprite sprite;

  TileSquare({
    required this.spritePosition,
    super.anchor = Anchor.topLeft,
    required super.position,
  }) : super(
          size: Vector2.all(worldTileSize),
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
      game.images.fromCache(tileMapImage),
      srcPosition: spritePosition,
      srcSize: spriteSize,
    );

    add(SpriteComponent(sprite: sprite, size: size));
  }
}
