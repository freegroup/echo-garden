import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/objects/flower.dart';
import 'package:echo_garden/game/objects/rabbit.dart';
import 'package:echo_garden/game/objects/square.dart';
import 'package:echo_garden/game/objects/tree.dart';
import 'package:echo_garden/game/objects/weed.dart';
import 'package:echo_garden/game/pixels.dart';
import 'package:echo_garden/model/actors/rabbit.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/representation/world_view.dart';
import 'package:flame/components.dart';

/// Creates the graphical tile for a model agent.
///
/// Only the agents that sit on top of the ground are made here (plants and
/// rabbits). The ground itself (water, beach, soil, mountains) is drawn by the
/// GroundRenderer.
AgentVisualization createVisualization(AgentView agent) {
  Vector2 position = cellToPixel(agent.cell);
  Type type = agent.type;

  if (type == RabbitAgent) {
    return RabbitTile(agent: agent, position: position);
  }
  if (type == PineModel) {
    return PineTile(agent: agent, position: position);
  }
  if (type == FirModel) {
    return FirTile(agent: agent, position: position);
  }
  if (type == TreeModel) {
    return TreeTile(agent: agent, position: position);
  }
  if (type == FlowerModel) {
    return FlowerTile(agent: agent, position: position);
  }
  if (type == WeedModel) {
    return WeedTile(agent: agent, position: position);
  }

  // unknown agent type: show it as a red square, so it is easy to spot
  return ColoredSquare.red(agent, position);
}
