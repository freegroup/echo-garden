import 'package:echo_garden/model/actors/rabbit.dart';
import 'package:echo_garden/representation/graphics/pixels.dart';
import 'package:echo_garden/representation/graphics/sprites/sprite_agent.dart';
import 'package:echo_garden/representation/graphics/sprites/sprite_rabbit.dart';
import 'package:echo_garden/representation/graphics/sprites/sprite_square.dart';
import 'package:echo_garden/representation/world_view.dart';
import 'package:flame/components.dart';

/// Creates the sprite for an agent that moves (see SpriteAgent): for now the
/// rabbits. What stays on its cell (ground, grass, plants) is drawn by the
/// tiles (see TileRenderer).
SpriteAgent createSprite(AgentView agent) {
  Vector2 position = cellToPixel(agent.cell);

  if (agent.type == RabbitAgent) {
    return SpriteRabbit(agent: agent, position: position);
  }

  // unknown agent type: show it as a red square, so it is easy to spot
  return SpriteSquare.red(agent, position);
}
