import 'dart:math';

import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/simulator.dart';

/// A simple scheduler that activates agents one at a time, in the order they were added.
///
/// This scheduler is designed to replicate the behavior of the scheduler in M
/// ASON, a multi-agent simulation toolkit. It assumes that each agent added
/// has a step method which takes no arguments and executes the agent’s actions.
///
class BaseScheduler {
  // the number of steps the scheduler has taken
  int steps = 0;

  // The model instance associated with the scheduler.
  final Simulator model;

  // the agents to manage
  late Set<Agent> agents;

  BaseScheduler({required this.model, Set<Agent>? agents}) {
    this.agents = agents ?? <Agent>{};
  }

  void add(agent) {
    if (!agents.contains(agent)) {
      agents.add(agent);
      model.add(agent);
    } else {
      print("is already member of the Scheduler: $agent");
    }
  }

  void remove(agent) {
    agents.remove(agent);
    model.remove(agent);
  }

  void step() {
    List<Agent> numbersList = agents.toList();
    for (Agent agent in numbersList) {
      agent.preStep();
      agent.step();
      agent.postStep();
    }
    steps += 1;
  }

  int get agentCount => agents.length;
}
