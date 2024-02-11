import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/objects/soil.dart';
import 'package:echo_garden/model/objects/seedable.dart';

class SoilModel extends SeedableModel {
  SoilModel({required super.gameModelRef, required super.cell, super.energy});

  @override
  AgentVisualization createVisualization() {
    assert(visualization == null);
    return visualization = SoilTile(
      agentModel: this,
      position: cell * kGameConfiguration.world.tileSize,
    );
  }

  @override
 Future<void> step() async  {}
}
