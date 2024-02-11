import 'dart:math';

import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/scheduler/base.dart';

class RandomScheduler extends BaseScheduler {
  RandomScheduler({required super.gameModelRef});

  @override
  Future<void> step() async {
    List<AgentModel> numbersList = agents.toList();
    numbersList.shuffle(Random());
    for (AgentModel agent in numbersList) {
      await agent.step();
    }
  }
}
