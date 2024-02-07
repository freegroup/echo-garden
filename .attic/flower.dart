import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/visual/objects/plant.dart';


class FlowerPatch extends Plant {
  FlowerPatch({required super.scheduler, super.x, super.y, super.cell}) {
    paint.color = kConfiguration.plant.flower.color;
    energy = kConfiguration.plant.flower.initialEnergy;
  }

  @override
  void step() {}
}
