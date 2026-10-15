import 'dart:collection';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/movement_mode.dart';
import 'package:echo_garden/model/objects/beach.dart';
import 'package:flutter_test/flutter_test.dart';

bool isWalkableLand(GameModel model, Cell cell) {
  bool onLand = model.getAgentAtCell(cell, SeedableModel.staticLayerId) != null ||
      model.getAgentAtCell(cell, PatchModel.staticLayerId) is BeachModel;
  return onLand && walking.canEnterCell(model, cell);
}

// How many walkable cells can be reached on foot from the start cell.
int reachableFrom(GameModel model, Cell start) {
  Set<Cell> seen = {start};
  Queue<Cell> toVisit = Queue.of([start]);
  while (toVisit.isNotEmpty) {
    Cell cell = toVisit.removeFirst();
    for (Cell next in [
      Cell(cell.x + 1, cell.y),
      Cell(cell.x - 1, cell.y),
      Cell(cell.x, cell.y + 1),
      Cell(cell.x, cell.y - 1),
    ]) {
      if (next.isInsideMap && isWalkableLand(model, next) && seen.add(next)) {
        toVisit.add(next);
      }
    }
  }
  return seen.length;
}

void main() {
  test('all walkable land is reachable on foot, on many maps', () {
    for (int seed = 0; seed < 25; seed++) {
      final model = GameModel(
          width: kGameConfiguration.grid.mapWidth,
          height: kGameConfiguration.grid.mapHeight,
          seed: seed);

      List<Cell> walkable = [];
      for (int x = 0; x < model.width; x++) {
        for (int y = 0; y < model.height; y++) {
          Cell cell = Cell(x, y);
          if (isWalkableLand(model, cell)) walkable.add(cell);
        }
      }

      expect(walkable, isNotEmpty, reason: 'seed $seed has no walkable land');
      expect(reachableFrom(model, walkable.first), walkable.length,
          reason: 'seed $seed: not all walkable land is connected');
    }
  });

  test('the same seed gives the same landscape', () {
    GameModel build() => GameModel(width: 60, height: 60, seed: 123);
    final a = build();
    final b = build();

    for (int x = 0; x < 60; x++) {
      for (int y = 0; y < 60; y++) {
        expect(a.groundTypeAt(Cell(x, y)), b.groundTypeAt(Cell(x, y)));
      }
    }
  });
}
