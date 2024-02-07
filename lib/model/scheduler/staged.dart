import 'dart:math';

import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/scheduler/base.dart';

class StagedScheduler extends BaseScheduler {
  StagedScheduler({required super.gameRef});

  @override
  void step() {
    List<AgentModel> numbersList = agents.toList();
    numbersList.shuffle(Random());
    for (AgentModel agent in numbersList) {
      agent.preStep();
    }
    for (AgentModel agent in numbersList) {
      agent.step();
    }
    for (AgentModel agent in numbersList) {
      agent.postStep();
    }
    steps += 1;
  }
}
