import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/objects/parched_grass.dart';
import 'package:echo_garden/model/objects/plant.dart';

class GrassModel extends PlantModel {
  GrassModel({required super.gameModelRef, required super.cell}) {
    energy = kGameConfiguration.plant.grass.initialEnergy;
    minEnergy = kGameConfiguration.plant.grass.minEnergy;
  }

  @override
  void step() {
    bool changed = false;
    changed |= _grow();
    if (changed) gameModelRef.notifyChanged(this);

    if (energy <= 0) {
      gameModelRef.remove(this);
      gameModelRef.add(ParchedGrassModel(gameModelRef: gameModelRef, cell: cell));
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
