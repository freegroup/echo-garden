import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/objects/weed.dart';
import 'package:echo_garden/model/objects/plant.dart';

class WeedModel extends PlantModel {
  WeedModel({required super.scheduler, super.x, super.y, super.cell}) {
    energy = kGameConfiguration.plant.weed.initialEnergy;
  }

  @override
  AgentVisualization createVisualization() {
    return WeedTile(agentModel: this, position: cell * kGameConfiguration.world.tileSize);
  }

  @override
  void step() {}
}
