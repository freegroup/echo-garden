import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/objects/beach.dart';
import 'package:echo_garden/game/objects/flat_water.dart';
import 'package:echo_garden/game/objects/flower.dart';
import 'package:echo_garden/game/objects/grass.dart';
import 'package:echo_garden/game/objects/parched_grass.dart';
import 'package:echo_garden/game/objects/rabbit.dart';
import 'package:echo_garden/game/objects/soil.dart';
import 'package:echo_garden/game/objects/square.dart';
import 'package:echo_garden/game/objects/tree.dart';
import 'package:echo_garden/game/objects/water.dart';
import 'package:echo_garden/game/objects/weed.dart';
import 'package:echo_garden/model/actors/rabbit.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/objects/beach.dart';
import 'package:echo_garden/model/objects/flat_water.dart';
import 'package:echo_garden/model/objects/parched_grass.dart';
import 'package:flame/components.dart';

/// Creates the graphical tile for a model agent.
AgentVisualization createVisualization(AgentModel agent, GameModel gameModel) {
  Vector2 position = agent.cell * kGameConfiguration.world.tileSize;

  if (agent is RabbitAgent) {
    return RabbitTile(agentModel: agent, position: position);
  }
  if (agent is TreeModel) {
    return TreeTile(agentModel: agent, position: position);
  }
  if (agent is FlowerModel) {
    return FlowerTile(agentModel: agent, position: position);
  }
  if (agent is GrassModel) {
    return GrassTile(agentModel: agent, position: position);
  }
  if (agent is ParchedGrassModel) {
    return ParchedGrassTile(agentModel: agent, position: position);
  }
  if (agent is WeedModel) {
    return WeedTile(agentModel: agent, position: position);
  }
  if (agent is SoilModel) {
    return SoilTile(agentModel: agent, position: position);
  }
  if (agent is BeachModel) {
    return _createBeachTile(agent, gameModel, position);
  }
  if (agent is FlatWaterModel) {
    return FlatWaterTile(agentModel: agent, position: position);
  }
  if (agent is WaterModel) {
    return WaterTile(agentModel: agent, position: position);
  }

  // unknown agent type: show it as a red square, so it is easy to spot
  return ColoredSquare.red(agent, position);
}

BeachTile _createBeachTile(BeachModel beach, GameModel gameModel, Vector2 position) {
  BeachTile tile = BeachTile(agentModel: beach, position: position);

  bool hasFlatWaterNeighbor(Vector2 direction) {
    try {
      return gameModel.getAgentAtCell(beach.cell + direction, PatchModel.staticLayerId)
          is FlatWaterModel;
    } catch (e) {
      // the neighbor is outside of the map
      return false;
    }
  }

  bool left = hasFlatWaterNeighbor(Vector2(-1, 0));
  bool leftTop = hasFlatWaterNeighbor(Vector2(-1, -1));
  bool top = hasFlatWaterNeighbor(Vector2(0, -1));
  bool topRight = hasFlatWaterNeighbor(Vector2(1, -1));
  bool right = hasFlatWaterNeighbor(Vector2(1, 0));
  bool bottomRight = hasFlatWaterNeighbor(Vector2(1, 1));
  bool bottom = hasFlatWaterNeighbor(Vector2(0, 1));
  bool bottomLeft = hasFlatWaterNeighbor(Vector2(-1, 1));

  // round a corner where the beach is surrounded by flat water
  tile.setCornerRounding(
    topLeft: left && leftTop && top,
    topRight: top && topRight && right,
    bottomRight: right && bottomRight && bottom,
    bottomLeft: left && bottomLeft && bottom,
  );
  return tile;
}
