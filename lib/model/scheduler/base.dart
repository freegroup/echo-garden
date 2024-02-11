import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/game.dart';

/// A simple scheduler that activates agents one at a time, in the order they were added.
///
/// This scheduler is designed to replicate the behavior of the scheduler in MASON,
/// a multi-agent simulation toolkit. It assumes that each agent added
/// has a step method which takes no arguments and executes the agent’s actions.
///
class BaseScheduler {
  // The model instance associated with the scheduler.
  final GameModel gameModelRef;

  // the agents to manage
  late Set<AgentModel> agents = <AgentModel>{};

  BaseScheduler({required this.gameModelRef});

  void add(AgentModel agent) {
    assert(agents.contains(agent) == false);
    agents.add(agent);
  }

  void remove(agent) {
    bool found = agents.remove(agent);
    assert(found);
  }

 Future<void> step() async {
    List<AgentModel> numbersList = agents.toList();
    for (AgentModel agent in numbersList) {
      await agent.step();
    }
  }
}
