import 'dart:math';

import 'package:echo_garden/model/cell.dart';

/// The eight compass directions. Each knows the step to the neighbor cell in
/// that direction (y grows downwards, so north is -1).
///
/// Used for the neighbors of a cell and for the wind.
enum Direction {
  north(Cell(0, -1)),
  northEast(Cell(1, -1)),
  east(Cell(1, 0)),
  southEast(Cell(1, 1)),
  south(Cell(0, 1)),
  southWest(Cell(-1, 1)),
  west(Cell(-1, 0)),
  northWest(Cell(-1, -1));

  /// The step to the neighbor cell in this direction.
  final Cell step;

  const Direction(this.step);

  // The direction as a vector of length 1, so a diagonal does not count more
  // than a straight direction.
  double get unitX => step.x / _length;
  double get unitY => step.y / _length;
  double get _length => sqrt(step.x * step.x + step.y * step.y);

  /// The direction that points most closely the same way as the vector
  /// (x, y): the one with the largest dot product.
  static Direction closestTo(double x, double y) {
    Direction best = Direction.north;
    double bestDot = double.negativeInfinity;
    for (Direction direction in Direction.values) {
      double dot = direction.unitX * x + direction.unitY * y;
      if (dot > bestDot) {
        bestDot = dot;
        best = direction;
      }
    }
    return best;
  }
}
