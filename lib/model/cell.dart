import 'dart:math';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/pos.dart';

/// A cell (tile) of the map, given by its column and row.
class Cell {
  final int x;
  final int y;

  const Cell(this.x, this.y);

  /// The middle of the cell, as a position in units.
  Pos get center {
    int gridWidth = kGameConfiguration.grid.gridWidth;
    return Pos(x * gridWidth + gridWidth ~/ 2, y * gridWidth + gridWidth ~/ 2);
  }

  bool get isInsideMap {
    return x >= 0 &&
        y >= 0 &&
        x < kGameConfiguration.grid.mapWidth &&
        y < kGameConfiguration.grid.mapHeight;
  }

  /// Straight-line distance in cells.
  double distanceTo(Cell other) {
    int dx = other.x - x;
    int dy = other.y - y;
    return sqrt(dx * dx + dy * dy);
  }

  Cell operator +(Cell other) => Cell(x + other.x, y + other.y);

  Cell operator -(Cell other) => Cell(x - other.x, y - other.y);

  @override
  bool operator ==(Object other) => other is Cell && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Cell($x, $y)';
}
