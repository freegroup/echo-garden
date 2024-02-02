import 'package:echo_garden/model/agent.dart';

abstract class Patch extends Agent {
  double energy;

  Patch({required super.scheduler, this.energy = 0, super.x, super.y, super.cell});

  @override
  void step() {}
}
