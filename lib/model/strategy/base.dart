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
}
