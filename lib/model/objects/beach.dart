import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/objects/beach.dart';
import 'package:echo_garden/model/objects/patch.dart';

class BeachModel extends PatchModel {
  BeachModel({required super.gameModelRef, required super.cell, super.energy});

  @override
  AgentVisualization createVisualization() {
    assert(visualization == null);

    return visualization =
        BeachTile(agentModel: this, position: cell * kGameConfiguration.world.tileSize);
  }
}
