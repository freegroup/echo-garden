import 'package:echo_garden/game/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';

class PlantComponent extends SpriteComponent
    with HasGameReference<EchoGardenGame>{

  EmberPlayer({
    required super.position,
  }) : super(size: Vector2.all(64), anchor: Anchor.center);

  @override
  void onLoad() {
  }
}

