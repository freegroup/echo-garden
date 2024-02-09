import 'package:echo_garden/game/objects/tile.dart';
import 'package:flame/components.dart';

class WaterTile extends TileSquare {
  WaterTile({required super.agentModel, required Vector2 position})
      : super(
            position: position,
            spriteFilenames: ["water-01.png", "water-02.png"]);
}
