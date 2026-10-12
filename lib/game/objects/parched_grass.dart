import 'dart:ui';

import 'package:echo_garden/game/objects/tile.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/rendering.dart';

class ParchedGrassTile extends TileSquare {
  OpacityEffect? opacityEffect;
  ParchedGrassTile({required super.agentModel, required Vector2 position})
      : super(
          position: position,
          spriteFilenames: [
            "grass-01.png",
            "grass-02.png",
            "grass-03.png",
            "grass-04.png",
            "grass-05.png",
            "grass-06.png",
            "grass-07.png",
          ],
        ) {
    decorator.addLast(PaintDecorator.tint(Color.fromARGB(255, 72, 85, 0)));
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    spriteComponent?.setOpacity(0.2);
  }
}
