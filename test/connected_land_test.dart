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

// Whether the cell lies in a block of 2 x 2 cells of walkable land: then the
// way through it is at least two cells wide.
bool inWalkableSquare(GameModel model, Cell cell) {
  for (int dx = -1; dx <= 0; dx++) {
    for (int dy = -1; dy <= 0; dy++) {
      bool square = true;
      for (int x = 0; x <= 1; x++) {
        for (int y = 0; y <= 1; y++) {
          if (!isWalkableLand(model, Cell(cell.x + dx + x, cell.y + dy + y))) {
            square = false;
          }
        }
      }
      if (square) return true;
    }
  }
  return false;
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

  test('no way is only one cell wide, on many maps', () {
    for (int seed = 0; seed < 10; seed++) {
      final model = GameModel(
          width: kGameConfiguration.grid.mapWidth,
          height: kGameConfiguration.grid.mapHeight,
          seed: seed);

      List<Cell> narrow = [];
      for (int x = 0; x < model.width; x++) {
        for (int y = 0; y < model.height; y++) {
          Cell cell = Cell(x, y);
          if (isWalkableLand(model, cell) && !inWalkableSquare(model, cell)) {
            narrow.add(cell);
          }
        }
      }
      expect(narrow, isEmpty,
          reason: 'seed $seed: ${narrow.length} cells only one cell wide, e.g. ${narrow.take(3)}');
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
