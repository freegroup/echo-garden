import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:flame/components.dart';

// Converts model coordinates (whole numbers) to pixels on the screen.
// Only the graphics know about pixels.

/// The top left corner of a cell, in pixels.
Vector2 cellToPixel(Cell cell) {
  double tileSize = kGameConfiguration.world.tileSize;
  return Vector2(cell.x * tileSize, cell.y * tileSize);
}

/// A position in units, in pixels.
Vector2 posToPixel(Pos pos) {
  double pixelsPerUnit = kGameConfiguration.world.tileSize / kGameConfiguration.grid.gridWidth;
  return Vector2(pos.x * pixelsPerUnit, pos.y * pixelsPerUnit);
}
