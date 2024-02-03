import 'package:echo_garden/scenario/configuration.dart';
import 'package:echo_garden/scenario/plant.dart';

class GrassPatch extends Plant {
  GrassPatch({required super.scheduler, super.x, super.y, super.cell}) {
    paint.color = kConfiguration.plant.grass.color;
    energy = kConfiguration.plant.grass.initialEnergy;
  }

  @override
  void step() {}
}
