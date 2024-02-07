
import 'package:echo_garden/model/game.dart';
import 'package:flame/components.dart';

class MovementStrategy {
  final GameModel model;

  MovementStrategy({required this.model}) {
    //
  }

  Set<Vector2> getNeighborhood({
    required Vector2 cell,
    bool includeCenter = false,
    int radius = 1,
    required String layerTypeId,
  }) {
    Set<Vector2> cells = {};

    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        if (!includeCenter && dx == 0 && dy == 0) continue;

        double newX = ((cell.x + dx + model.width) % model.width);
        double newY = ((cell.y + dy + model.height) % model.height);
        Vector2 newCell = Vector2(newX, newY);
        if (model.getAgentAtCell(newCell, layerTypeId) == null) {
          cells.add(newCell);
        }
      }
    }
    return cells;
  }
}
