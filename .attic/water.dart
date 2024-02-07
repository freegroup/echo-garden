import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/visual/objects/patch.dart';

class WaterPatch extends Patch {
  WaterPatch({required super.scheduler, super.x, super.y, super.cell}) {
    paint.color = kConfiguration.patch.water.color;
  }

  @override
  void step() {}
}
