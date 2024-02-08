import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/objects/grass.dart';
import 'package:echo_garden/model/objects/plant.dart';

class GrassModel extends PlantModel {
  GrassModel({required super.scheduler, super.x, super.y, super.cell}) {
    energy = kGameConfiguration.plant.grass.initialEnergy;
  }

  @override
  AgentVisualization createVisualization() {
    return GrassTile(agentModel: this, position: cell * kGameConfiguration.world.tileSize);
  }

  @override
  void step() {}
}
