import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/objects/flower.dart';
import 'package:echo_garden/model/objects/plant.dart';

class FlowerModel extends PlantModel {
  FlowerModel({required super.gameModelRef, required super.cell, super.energy}) {
    energy = kGameConfiguration.plant.flower.initialEnergy;
  }

  @override
  AgentVisualization createVisualization() {
    assert(visualization == null);
    return visualization = FlowerTile(
      agentModel: this,
      position: cell * kGameConfiguration.world.tileSize,
    );
  }

  @override
  Future<void> step() async {
    var changed = false;
    changed |= _grow();

    if (changed) await visualization?.onModelChange();

    if (energy <= 0) {
      gameModelRef.remove(this);
    }
  }

  bool _grow() {
    return super.grow(
      kGameConfiguration.plant.flower.growEnergy,
      kGameConfiguration.plant.flower.maxEnergy,
      kGameConfiguration.plant.flower.requiresMinWaterLevel,
    );
  }
}
