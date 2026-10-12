import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/objects/beach.dart';
import 'package:echo_garden/model/objects/flat_water.dart';
import 'package:echo_garden/model/objects/patch.dart';
import 'package:flame/components.dart';

class BeachModel extends PatchModel {
  BeachModel({required super.gameModelRef, required super.cell, super.energy});

  @override
  AgentVisualization createVisualization() {
    assert(visualization == null);
    BeachTile beach = visualization = BeachTile(
      agentModel: this,
      position: cell * kGameConfiguration.world.tileSize,
    );

    // Simplify checking for neighboring cells using a helper function
    bool hasNeighbor(Vector2 direction) {
      try {
        return gameModelRef.getAgentAtCell(cell + direction, PatchModel.staticLayerId)
            is FlatWaterModel;
      } catch (e) {
        return false;
      }
    }

    var leftCell = hasNeighbor(Vector2(-1, 0));
    var leftTopCell = hasNeighbor(Vector2(-1, -1));
    var topCell = hasNeighbor(Vector2(0, -1));
    var topRightCell = hasNeighbor(Vector2(1, -1));
    var rightCell = hasNeighbor(Vector2(1, 0));
    var bottomRightCell = hasNeighbor(Vector2(1, 1));
    var bottomCell = hasNeighbor(Vector2(0, 1));
    var bottomLeftCell = hasNeighbor(Vector2(-1, 1));

    // Set corner rounding based on the presence of neighbors
    beach.setCornerRounding(
      topLeft: leftCell && leftTopCell && topCell,
      topRight: topCell && topRightCell && rightCell,
      bottomRight: rightCell && bottomRightCell && bottomCell,
      bottomLeft: leftCell && bottomLeftCell && bottomCell,
    );
    return visualization!;
  }
}
