import 'package:echo_garden/scenario/configuration.dart';
import 'package:echo_garden/scenario/patch.dart';

class WeedPatch extends Patch {
  WeedPatch({required super.scheduler, super.x, super.y, super.cell}) {
    paint.color = kConfiguration.plant.weed.color;
    energy = kConfiguration.plant.weed.initialEnergy;
  }

  @override
  void step() {}
}
