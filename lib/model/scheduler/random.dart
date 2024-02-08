import 'dart:math';

import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/scheduler/base.dart';

class RandomScheduler extends BaseScheduler {
  RandomScheduler({required super.gameModelRef});

  @override
  void step() {
    List<AgentModel> numbersList = agents.toList();
    numbersList.shuffle(Random());
    for (AgentModel agent in numbersList) {
      agent.preStep();
      agent.step();
      agent.postStep();
    }
    steps += 1;
  }
}
