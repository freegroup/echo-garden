import 'package:echo_garden/game/objects/tile.dart';
import 'package:flame/components.dart';

class WeedTile extends TileSquare {
  WeedTile({required super.agentModel, required Vector2 position})
      : super(
          position: position,
          spriteFilenames: ["fir-01.png", "fir-02.png"],
        );
}
