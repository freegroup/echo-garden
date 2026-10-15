import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/objects/flower.dart';
import 'package:echo_garden/game/objects/rabbit.dart';
import 'package:echo_garden/game/objects/square.dart';
import 'package:echo_garden/game/objects/tree.dart';
import 'package:echo_garden/game/objects/weed.dart';
import 'package:echo_garden/game/pixels.dart';
import 'package:echo_garden/model/actors/rabbit.dart';
import 'package:echo_garden/model/index.dart';
import 'package:flame/components.dart';

/// Creates the graphical tile for a model agent.
///
/// Only the agents that sit on top of the ground are made here (plants and
/// rabbits). The ground itself (water, beach, soil, mountains) is drawn by the
/// GroundRenderer.
AgentVisualization createVisualization(AgentModel agent, GameModel gameModel) {
  Vector2 position = cellToPixel(agent.cell);

  if (agent is RabbitAgent) {
    return RabbitTile(agentModel: agent, position: position);
  }
  // firs and pines are trees as well, so they must be checked first
  if (agent is PineModel) {
    return PineTile(agentModel: agent, position: position);
  }
  if (agent is FirModel) {
    return FirTile(agentModel: agent, position: position);
  }
  if (agent is TreeModel) {
    return TreeTile(agentModel: agent, position: position);
  }
  if (agent is FlowerModel) {
    return FlowerTile(agentModel: agent, position: position);
  }
  if (agent is WeedModel) {
    return WeedTile(agentModel: agent, position: position);
  }

  // unknown agent type: show it as a red square, so it is easy to spot
  return ColoredSquare.red(agent, position);
}
