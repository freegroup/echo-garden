import 'package:echo_garden/scenario/configuration.dart';
import 'package:echo_garden/scenario/patch.dart';

class WaterPatch extends Patch {
  WaterPatch({required super.scheduler, super.x, super.y, super.cell}) {
    paint.color = kConfiguration.patch.water.color;
  }

  @override
  void step() {}
}
