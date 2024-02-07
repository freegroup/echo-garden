import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/visual/objects/plant.dart';

class GrassPatch extends Plant {
  GrassPatch({required super.scheduler, super.x, super.y, super.cell}) {
    paint.color = kConfiguration.plant.grass.color;
    energy = kConfiguration.plant.grass.initialEnergy;
  }

  @override
  void step() {}
}
