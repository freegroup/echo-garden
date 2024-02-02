import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/intvector2.dart';
import 'package:echo_garden/model/simulator.dart';
import 'package:flame/components.dart';

class MovementStrategy {
  final Simulator model;

  MovementStrategy({required this.model}) {
    //
  }

  Set<Vector2> getNeighborhood({
    required Vector2 cell,
    bool includeCenter = false,
    int radius = 1,
  }) {
    Set<Vector2> cells = {};

    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        if (!includeCenter && dx == 0 && dy == 0) continue;

        double newX = (cell.x + dx + model.width) % model.width;
        double newY = (cell.y + dy + model.height) % model.height;

        cells.add(Vector2(newX, newY));
      }
    }
    return cells;
  }

  Set<IntVector2> getNeighborhoodWithoutType<T extends Agent>({
    required IntVector2 cell,
    bool includeCenter = false,
    int radius = 1,
  }) {
    Set<IntVector2> cells = {};

    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        if (!includeCenter && dx == 0 && dy == 0) continue;

        int newX = (cell.x + dx + model.width) % model.width;
        int newY = (cell.y + dy + model.height) % model.height;
        IntVector2 newCell = IntVector2(newX, newY);
        if (model.getAgentAtPosition<T>(newCell) == null) {
          cells.add(newCell);
        }
      }
    }
    return cells;
  }
}
