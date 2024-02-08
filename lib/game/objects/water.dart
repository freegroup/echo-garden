import 'dart:math';

import 'package:echo_garden/game/objects/tile.dart';
import 'package:flame/components.dart';

class WaterTile extends TileSquare {
  WaterTile({required super.agentModel, required Vector2 position})
      : super(
            position: position,
            spritePosition: Random().nextBool() ? Vector2(32, 224) : Vector2(128, 224));
}
