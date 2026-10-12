import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/objects/parched_grass.dart';
import 'package:echo_garden/model/objects/plant.dart';

class ParchedGrassModel extends PlantModel {
  ParchedGrassModel({required super.gameModelRef, required super.cell}) {
    energy = kGameConfiguration.plant.parchedGrass.initialEnergy;
    minEnergy = kGameConfiguration.plant.parchedGrass.minEnergy;
  }

  @override
  AgentVisualization createVisualization() {
    assert(visualization == null);
    return visualization = ParchedGrassTile(
      agentModel: this,
      position: cell * kGameConfiguration.world.tileSize,
    );
  }

  @override
  Future<void> step() async {
    bool changed = false;
    changed |= _grow();
    if (changed && visualization != null) await visualization!.onModelChange();
  }

  bool _grow() {
    return super.grow(
      kGameConfiguration.plant.parchedGrass.growEnergy,
      kGameConfiguration.plant.parchedGrass.maxEnergy,
      kGameConfiguration.plant.parchedGrass.requiresMinWaterLevel,
    );
  }
}
