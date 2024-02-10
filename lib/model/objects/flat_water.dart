import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/objects/flat_water.dart';
import 'package:echo_garden/model/objects/patch.dart';

class FlatWaterModel extends PatchModel {
  FlatWaterModel({required super.gameModelRef, required super.cell, super.energy});

  @override
  AgentVisualization createVisualization() {
    assert(visualization == null);
    return visualization = FlatWaterTile(
      agentModel: this,
      position: cell * kGameConfiguration.world.tileSize,
    );
  }
}
