import 'dart:math';

import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/scheduler/base.dart';

class StagedScheduler extends BaseScheduler {
  StagedScheduler({required super.model, super.agents});

  @override
  void step() {
    List<Agent> numbersList = agents.toList();
    numbersList.shuffle(Random());
    for (Agent agent in numbersList) {
      agent.preStep();
    }
    for (Agent agent in numbersList) {
      agent.step();
    }
    for (Agent agent in numbersList) {
      agent.postStep();
    }
    steps += 1;
  }
}
