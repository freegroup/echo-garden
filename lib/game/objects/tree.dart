import 'package:echo_garden/game/objects/tile.dart';
import 'package:flame/components.dart';

class TreeTile extends TileSquare {
  TreeTile({required super.agentModel, required Vector2 position})
      : super(
            position: position,
            spriteFilenames: ["tree-01.png", "tree-02.png"]);
}
