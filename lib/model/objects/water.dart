import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/objects/water.dart';
import 'package:echo_garden/model/objects/patch.dart';

class WaterModel extends PatchModel {
  WaterModel({required super.scheduler, super.x, super.y, super.cell}) {}

  @override
  AgentVisualization createVisualization() {
    return WaterTile(agentModel: this, position: cell * kGameConfiguration.world.tileSize);
  }

  @override
  void step() {}
}
