import 'package:echo_garden/scenario/configuration.dart';
import 'package:echo_garden/scenario/patch.dart';

class FlowerPatch extends Patch {
  FlowerPatch({required super.scheduler, super.x, super.y, super.cell}) {
    paint.color = kConfiguration.plant.flower.color;
    energy = kConfiguration.plant.flower.initialEnergy;
  }

  @override
  void step() {}
}
