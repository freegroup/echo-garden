import 'package:echo_garden/game/objects/masked_tile.dart';
import 'package:flame/components.dart';

class BeachTile extends MaskedTileSquare {
  BeachTile({required super.agentModel, required Vector2 position})
      : super(
            position: position,
            spriteFilename: "beach-01.png",
            baseLayerFilename: "water-beach-01.png") {
    roundBottomLeft = true;
  }
}
