import 'dart:math';

import 'package:echo_garden/game/objects/tile.dart';
import 'package:flame/components.dart';

class WeedTile extends TileSquare {
  WeedTile({required super.agentModel, required Vector2 position})
      : super(
          position: position,
          spritePosition: Random().nextBool() ? Vector2(32, 512) : Vector2(128, 512),
        );
}
