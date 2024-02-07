import 'package:echo_garden/utils/intvector2.dart';
import 'package:echo_garden/model/game.dart';

class MovementStrategy {
  final GameModel model;

  MovementStrategy({required this.model}) {
    //
  }

  Set<IntVector2> getNeighborhood({
    required IntVector2 cell,
    bool includeCenter = false,
    int radius = 1,
    required String layerTypeId,
  }) {
    Set<IntVector2> cells = {};

    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        if (!includeCenter && dx == 0 && dy == 0) continue;

        int newX = ((cell.x + dx + model.width) % model.width);
        int newY = ((cell.y + dy + model.height) % model.height);
        IntVector2 newCell = IntVector2(newX, newY);
        if (model.getAgentAtCell(newCell, layerTypeId) == null) {
          cells.add(newCell);
        }
      }
    }
    return cells;
  }
}
