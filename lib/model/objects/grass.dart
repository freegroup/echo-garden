import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/objects/plant.dart';

class GrassModel extends PlantModel {
  GrassModel({required super.scheduler, super.x, super.y, super.cell}) {
    energy = kConfiguration.plant.grass.initialEnergy;
  }

  @override
  void step() {}
}
