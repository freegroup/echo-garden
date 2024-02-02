import 'package:echo_garden/scenario/configuration.dart';
import 'package:echo_garden/scenario/patch.dart';

class GrassPatch extends Patch {
  GrassPatch({required super.scheduler, super.x, super.y, super.cell}) {
    paint.color = kConfiguration.plant.grass.color;
    energy = kConfiguration.plant.grass.initialEnergy;
  }

  @override
  void step() {}
}
