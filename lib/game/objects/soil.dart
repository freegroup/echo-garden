import 'package:echo_garden/game/objects/tile.dart';
import 'package:flame/components.dart';

class SoilTile extends TileSquare {
  SoilTile({required super.agentModel, required Vector2 position})
      : super(
            position: position,
           spriteFilenames: ["soil-01.png", "soil-02.png"]);
}
