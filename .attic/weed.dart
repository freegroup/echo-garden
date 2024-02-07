import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/visual/objects/plant.dart';

class WeedPatch extends Plant {
  WeedPatch({required super.scheduler, super.x, super.y, super.cell}) {
    paint.color = kConfiguration.plant.weed.color;
    energy = kConfiguration.plant.weed.initialEnergy;
  }

  @override
  void step() {}
}
