import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/objects/plant.dart';

class FlowerModel extends PlantModel {
  FlowerModel({required super.scheduler, super.x, super.y, super.cell}) {
    energy = kConfiguration.plant.flower.initialEnergy;
  }

  @override
  void step() {}
}
