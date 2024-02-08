import 'dart:math';

import 'package:echo_garden/game/objects/tile.dart';
import 'package:flame/components.dart';

class GrassTile extends TileSquare {
  GrassTile({required super.agentModel, required Vector2 position})
      : super(
            position: position,
            spritePosition: Random().nextBool() ? Vector2(32, 32) : Vector2(128, 32));
}
