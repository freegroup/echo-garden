import 'package:echo_garden/model/agent.dart';

abstract class Patch extends Agent {
  Patch({required super.scheduler, super.x, super.y, super.cell});

  @override
  void step() {}
}
