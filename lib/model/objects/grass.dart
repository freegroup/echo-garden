import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/objects/grass.dart';
import 'package:echo_garden/model/objects/plant.dart';

class GrassModel extends PlantModel {
  GrassModel({required super.gameModelRef, required super.cell}) {
    energy = kGameConfiguration.plant.grass.initialEnergy;
    minEnergy = kGameConfiguration.plant.grass.minEnergy;
  }

  @override
  AgentVisualization createVisualization() {
    assert(visualization == null);
    return visualization = GrassTile(
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
      kGameConfiguration.plant.grass.growEnergy,
      kGameConfiguration.plant.grass.maxEnergy,
      kGameConfiguration.plant.grass.requiresMinWaterLevel,
    );
  }
}
