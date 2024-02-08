import 'dart:math';

import 'package:echo_garden/game/objects/tile.dart';
import 'package:flame/components.dart';

class TreeTile extends TileSquare {
  TreeTile({required super.agentModel, required Vector2 position})
      : super(
            position: position,
            spritePosition: Random().nextBool() ? Vector2(32, 320) : Vector2(128, 320));
}
