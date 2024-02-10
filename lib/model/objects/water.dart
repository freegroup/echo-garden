import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/objects/water.dart';
import 'package:echo_garden/model/objects/patch.dart';

class WaterModel extends PatchModel {
  WaterModel({required super.gameModelRef, required super.cell, super.energy});

  @override
  AgentVisualization createVisualization() {
    assert(visualization == null);

    return visualization= WaterTile(agentModel: this, position: cell * kGameConfiguration.world.tileSize);
  }

  @override
  void step() {}
}
