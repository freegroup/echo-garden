import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/intvector2.dart';
import 'package:echo_garden/model/random.dart';
import 'package:flame/game.dart';

abstract class Simulator extends FlameGame {
  final int width;
  final int height;
  //late Set<Agent> agents;
  final Map<IntVector2, Set<Agent>> agentsByCell = {};

  Simulator({required this.width, required this.height});

  @override
  void add(component) {
    if (component is Agent) {
      Vector2 newCellSize = Vector2(size.x / width, size.y / height);
      component.resize(size, newCellSize);
      final cell = component.cell;
      agentsByCell.putIfAbsent(cell, () => {}).add(component);
    }
    super.add(component);
  }

  @override
  void remove(component) {
    if (component is Agent) {
      final cell = component.cell;
      agentsByCell[cell]?.remove(component);
    }
    super.remove(component);
  }

  // Call this method when an agent moves to a new cell
  void move(Agent agent, IntVector2 newCell) {
    // Remove from old cell
    final oldCell = agent.cell;
    agentsByCell[oldCell]?.remove(agent);

    // Add to new cell
    agent.cell = newCell; // Update the agent's cell to the new cell
    agentsByCell.putIfAbsent(newCell, () => {}).add(agent);
  }

  // Method to get a random agent of type T at a specific cell position
  T? getAgentAtPosition<T extends Agent>(IntVector2 cell) {
    var agentsAtCell = agentsByCell[cell];
    if (agentsAtCell != null) {
      var filteredAgents = agentsAtCell.where((agent) => agent is T).cast<T>();
      return pickRandomElement(filteredAgents.toSet());
    }
    return null;
  }

  void step();
}
