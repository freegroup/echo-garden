import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/cell.dart';
import 'package:echo_garden/model/game.dart';

class MovementStrategy {
  final GameModel model;

  MovementStrategy({required this.model});

  /// All cells of the map within the radius around a cell.
  Set<Cell> getCellsAround({required Cell cell, int radius = 1, bool includeCenter = false}) {
    Set<Cell> cells = {};
    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        if (!includeCenter && dx == 0 && dy == 0) continue;
        Cell around = Cell(cell.x + dx, cell.y + dy);
        if (around.x >= 0 && around.x < model.width && around.y >= 0 && around.y < model.height) {
          cells.add(around);
        }
      }
    }
    return cells;
  }

  Set<Cell> getNeighborhood({
    required Cell cell,
    bool includeCenter = false,
    bool emptyCellsLookup = true,
    int radius = 1,
    required String layerId,
  }) {
    Set<Cell> cells = {};

    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        if (!includeCenter && dx == 0 && dy == 0) continue; // Skip the center cell if not included

        int newX = cell.x + dx;
        int newY = cell.y + dy;

        // Check if the new position is within the world boundaries
        if (newX >= 0 && newX < model.width && newY >= 0 && newY < model.height) {
          Cell newCell = Cell(newX, newY);

          // Optionally check if there's an agent at the new cell position, depending on your requirements
          if ((model.getAgentAtCell(newCell, layerId) == null) == emptyCellsLookup) {
            cells.add(newCell);
          }
        }
      }
    }
    return cells;
  }

  Set<Cell> getNeighborhoodByType({
    required Cell cell,
    bool includeCenter = false,
    int radius = 1,
    required Type type,
    required String layerId,
  }) {
    Set<Cell> cells = {};

    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        if (!includeCenter && dx == 0 && dy == 0) continue; // Skip the center cell if not included

        int newX = cell.x + dx;
        int newY = cell.y + dy;

        // Check if the new position is within the world boundaries
        if (newX >= 0 && newX < model.width && newY >= 0 && newY < model.height) {
          Cell newCell = Cell(newX, newY);

          // Optionally check if there's an agent at the new cell position, depending on your requirements
          var foundAgent = model.getAgentAtCell(newCell, layerId);
          if ((foundAgent.runtimeType == type)) {
            cells.add(newCell);
          }
        }
      }
    }
    return cells;
  }

  bool isAgentTypeNeighborOnLayer({
    required Cell cell,
    int radius = 1,
    required Type type,
    required String layerId,
  }) {
    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        if (dx == 0 && dy == 0) continue; // Skip the center cell if not included

        int newX = cell.x + dx;
        int newY = cell.y + dy;

        // Check if the new position is within the world boundaries
        if (newX >= 0 && newX < model.width && newY >= 0 && newY < model.height) {
          Cell newCell = Cell(newX, newY);
          AgentModel? agentAtCell = model.getAgentAtCell(newCell, layerId);
          if (agentAtCell != null && agentAtCell.runtimeType == type) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Cell? getNearestCellForAgentTypeOnLayer({
    required Cell cell,
    int radius = 10,
    required Type type,
    required String layerId,
  }) {
    double nearestDistance = -1;
    Cell? nearestCell;
    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        if (dx == 0 && dy == 0) continue; // Skip the center cell

        int newX = cell.x + dx;
        int newY = cell.y + dy;

        // Check if the new position is within the world boundaries
        if (newX >= 0 && newX < model.width && newY >= 0 && newY < model.height) {
          Cell newCell = Cell(newX, newY);
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
    required Cell cell,
    int radius = 10,
    required Type type,
    required String layerId,
  }) {
    double aggregatedEnergy = 0;
    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        if (dx == 0 && dy == 0) continue; // Skip the center cell

        int newX = cell.x + dx;
        int newY = cell.y + dy;

        // Check if the new position is within the world boundaries
        if (newX >= 0 && newX < model.width && newY >= 0 && newY < model.height) {
          Cell newCell = Cell(newX, newY);
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
