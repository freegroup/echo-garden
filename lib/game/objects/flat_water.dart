import 'package:echo_garden/game/objects/tile.dart';
import 'package:flame/components.dart';

class FlatWaterTile extends TileSquare {
  FlatWaterTile({required super.agentModel, required Vector2 position})
      : super(position: position, spriteFilenames: ["water-beach-01.png", "water-beach-02.png"]);
}
