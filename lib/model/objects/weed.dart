import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/objects/weed.dart';
import 'package:echo_garden/model/objects/plant.dart';

class WeedModel extends PlantModel {
  WeedModel({required super.gameModelRef, required super.cell, super.energy}) {
    energy = kGameConfiguration.plant.weed.initialEnergy;
  }

  @override
  AgentVisualization createVisualization() {
    assert(visualization == null);
    return visualization = WeedTile(
      agentModel: this,
      position: cell * kGameConfiguration.world.tileSize,
    );
  }

  @override
  Future<void> step() async {
    bool changed = false;
    changed |= _grow();
    if (changed && visualization != null) await visualization!.onModelChange();

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
