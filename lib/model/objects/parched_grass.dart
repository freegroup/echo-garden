import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/objects/plant.dart';

class ParchedGrassModel extends PlantModel {
  ParchedGrassModel({required super.gameModelRef, required super.cell}) {
    energy = kGameConfiguration.plant.parchedGrass.initialEnergy;
    minEnergy = kGameConfiguration.plant.parchedGrass.minEnergy;
  }

  @override
  void step() {
    _grow();
  }

  bool _grow() {
    return super.grow(
      kGameConfiguration.plant.parchedGrass.growEnergy,
      kGameConfiguration.plant.parchedGrass.maxEnergy,
      kGameConfiguration.plant.parchedGrass.requiresMinWaterLevel,
    );
  }
}
