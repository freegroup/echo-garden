import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/scenario/patch.dart';

abstract class Plant extends Patch {
  double energy;

  Plant({required super.scheduler, this.energy=0, super.x, super.y, super.cell});

  @override
  void step() {}
}
