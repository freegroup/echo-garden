import 'package:echo_garden/game/objects/tile.dart';
import 'package:flame/components.dart';

class BeachTile extends TileSquare {
  BeachTile({required super.agentModel, required Vector2 position})
      : super(position: position, spriteFilenames: ["beach-01.png", "beach-02.png"]);
}
