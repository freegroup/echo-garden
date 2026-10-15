import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/objects/plant.dart';

class FlowerModel extends PlantModel {
  FlowerModel({required super.gameModelRef, required super.cell, super.energy}) {
    energy = kGameConfiguration.plant.flower.initialEnergy;
  }

  @override
  void step() {
    var changed = false;
    changed |= _grow();

    if (changed) gameModelRef.notifyChanged(this);

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
