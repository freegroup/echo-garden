import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/game.dart';
import 'package:flame/components.dart';

class MovementStrategy {
  final GameModel model;

  MovementStrategy({required this.model});

  Set<Vector2> getNeighborhood({
    required Vector2 cell,
    bool includeCenter = false,
    bool emptyCellsLookup = true,
    int radius = 1,
    required String layerId,
  }) {
    Set<Vector2> cells = {};

    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        if (!includeCenter && dx == 0 && dy == 0) continue; // Skip the center cell if not included

        double newX = cell.x + dx;
        double newY = cell.y + dy;

        // Check if the new position is within the world boundaries
        if (newX >= 0 && newX < model.width && newY >= 0 && newY < model.height) {
          Vector2 newCell = Vector2(newX, newY);

          // Optionally check if there's an agent at the new cell position, depending on your requirements
          if ((model.getAgentAtCell(newCell, layerId) == null) == emptyCellsLookup) {
            cells.add(newCell);
          }
        }
      }
    }
    return cells;
  }

  bool isAgentTypeNeighborOnLayer({
    required Vector2 cell,
    int radius = 1,
    required Type type,
    required String layerId,
  }) {
    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        if (dx == 0 && dy == 0) continue; // Skip the center cell if not included

        double newX = cell.x + dx;
        double newY = cell.y + dy;

        // Check if the new position is within the world boundaries
        if (newX >= 0 && newX < model.width && newY >= 0 && newY < model.height) {
          Vector2 newCell = Vector2(newX, newY);
          AgentModel? agentAtCell = model.getAgentAtCell(newCell, layerId);
          if (agentAtCell != null && agentAtCell.runtimeType == type) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Vector2? getNearestCellForAgentTypeOnLayer({
    required Vector2 cell,
    int radius = 10,
    required Type type,
    required String layerId,
  }) {
    double nearestDistance = -1;
    Vector2? nearestCell;
    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        if (dx == 0 && dy == 0) continue; // Skip the center cell

        double newX = cell.x + dx;
        double newY = cell.y + dy;

        // Check if the new position is within the world boundaries
        if (newX >= 0 && newX < model.width && newY >= 0 && newY < model.height) {
          Vector2 newCell = Vector2(newX, newY);
          AgentModel? agentAtCell = model.getAgentAtCell(newCell, layerId);

          if (agentAtCell != null && agentAtCell.runtimeType == type) {
            double distance = cell.distanceTo(newCell);
            if (nearestDistance == -1 || distance < nearestDistance) {
              nearestDistance = distance;
              nearestCell = newCell;
            }
          }
        }
      }
    }

    return nearestCell;
  }


  double getAggregatedEnergyForAgentTypeOnLayer({
    required Vector2 cell,
    int radius = 10,
    required Type type,
    required String layerId,
  }) {
    double aggregatedEnergy = 0;
    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        if (dx == 0 && dy == 0) continue; // Skip the center cell

        double newX = cell.x + dx;
        double newY = cell.y + dy;

        // Check if the new position is within the world boundaries
        if (newX >= 0 && newX < model.width && newY >= 0 && newY < model.height) {
          Vector2 newCell = Vector2(newX, newY);
          AgentModel? agentAtCell = model.getAgentAtCell(newCell, layerId);

          if (agentAtCell != null && agentAtCell.runtimeType == type) {
            aggregatedEnergy += agentAtCell.energy;
          }
        }
      }
    }
    return aggregatedEnergy;
  }
}
