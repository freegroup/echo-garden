import 'dart:math';

import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/scheduler/base.dart';

class RandomPercentScheduler extends BaseScheduler {
  // 0-100%
  final int percent;

  RandomPercentScheduler({required this.percent, required super.gameModelRef});

  @override
  void step() {
    // Convert percent to a fraction and calculate the number of agents to step
    final int agentsToStep = (agents.length * (percent / 100.0)).round();

    // Shuffle the list of agents
    List<AgentModel> shuffledAgents = List.from(agents)..shuffle(Random());

    // Pick the first 'agentsToStep' agents from the shuffled list and step through them
    for (AgentModel agent in shuffledAgents.take(agentsToStep)) {
      agent.step();
    }
  }
}
