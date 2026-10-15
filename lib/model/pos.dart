import 'dart:math';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/cell.dart';

/// A position in the world, in units without a name.
///
/// One cell is `gridWidth` units wide (see configuration). Positions are
/// always whole numbers; the representations convert them, e.g. to pixels.
class Pos {
  final int x;
  final int y;

  const Pos(this.x, this.y);

  /// The cell this position lies in.
  Cell get cell {
    int gridWidth = kGameConfiguration.grid.gridWidth;
    // floor, so that positions left of or above the map get negative cells
    return Cell((x / gridWidth).floor(), (y / gridWidth).floor());
  }

  /// Straight-line distance in units.
  double distanceTo(Pos other) {
    int dx = other.x - x;
    int dy = other.y - y;
    return sqrt(dx * dx + dy * dy);
  }

  Pos operator +(Pos other) => Pos(x + other.x, y + other.y);

  Pos operator -(Pos other) => Pos(x - other.x, y - other.y);

  @override
  bool operator ==(Object other) => other is Pos && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Pos($x, $y)';
}
