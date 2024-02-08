import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/objects/soil.dart';
import 'package:echo_garden/model/objects/seedable.dart';

class SoilModel extends SeedableModel {
  SoilModel({required super.scheduler, super.x, super.y, super.cell});

  @override
  AgentVisualization createVisualization() {
    return SoilTile(agentModel: this, position: cell * kGameConfiguration.world.tileSize);
  }

  @override
  void step() {}
}
