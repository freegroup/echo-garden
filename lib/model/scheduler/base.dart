import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/game.dart';

/// A simple scheduler that activates agents one at a time, in the order they were added.
///
/// This scheduler is designed to replicate the behavior of the scheduler in MASON,
/// a multi-agent simulation toolkit. It assumes that each agent added
/// has a step method which takes no arguments and executes the agent’s actions.
///
class BaseScheduler {
  // the number of steps the scheduler has taken
  int steps = 0;

  // The model instance associated with the scheduler.
  final GameModel gameRef;

  // the agents to manage
  late Set<AgentModel> agents = <AgentModel>{};

  BaseScheduler({required this.gameRef});

  void add(AgentModel agent) {
    if (!agents.contains(agent)) {
      agents.add(agent);
      gameRef.add(agent);
    } else {
      print("is already member of the Scheduler: $agent");
    }
  }

  void remove(agent) {
    agents.remove(agent);
  }

  void step() {
    List<AgentModel> numbersList = agents.toList();
    for (AgentModel agent in numbersList) {
      agent.preStep();
      agent.step();
      agent.postStep();
    }
    steps += 1;
  }

  int get agentCount => agents.length;
}
