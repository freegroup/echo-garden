import 'package:echo_garden/representation/graphics/game.dart';
import 'package:echo_garden/representation/world_view.dart';
import 'package:flame/components.dart';

/// The sprite of one agent that moves, e.g. a rabbit: an object of its own
/// with a memory, e.g. where it is on its way from one cell to the next.
/// It follows its agent in the world view.
///
/// What stays on its cell needs no memory and is drawn by a tile (see Tile).
abstract class SpriteAgent extends PositionComponent with HasGameReference<GameVisualization> {
  final AgentView agent;
  SpriteAgent({
    required this.agent,
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.nativeAngle,
    super.anchor,
    super.children,
    super.priority,
    super.key,
  });

  Future<void> onModelChange() async {}
}
