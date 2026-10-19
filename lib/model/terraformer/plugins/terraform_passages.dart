import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/objects/beach.dart';
import 'package:echo_garden/model/terraformer/terraform_plugin.dart';
import 'package:echo_garden/model/terraformer/terrain_map.dart';

/// The ways for the player: all walkable land is connected, and no way is
/// only one cell wide.
///
/// It runs last among the areas: the beaches or the mountains may have cut
/// something off again, e.g. a valley behind high peaks.
class TerraformPassages extends TerraformPlugin {
  @override
  void phase03Areas(TerrainMap map) {
    connectRegions(
      map,
      (cell) => isWalkableLand(map, cell),
      (cell) => _buildWalkablePassage(map, cell),
    );
    _widenNarrowPassages(map);
  }

  // A way only one cell wide is hard to find and to walk, by eye and even more
  // by ear. So every cell of walkable land must lie in a walkable block of
  // 2 x 2 cells; where one does not, the land around it is made walkable, three
  // cells wide. This only adds walkable land, so everything stays reachable.
  void _widenNarrowPassages(TerrainMap map) {
    // a limit, so a mistake can never hang the game
    for (int round = 0; round < 10; round++) {
      List<Cell> narrow = [];
      for (int x = 0; x < map.width; x++) {
        for (int y = 0; y < map.height; y++) {
          Cell cell = Cell(x, y);
          if (isWalkableLand(map, cell) && !_inWalkableSquare(map, cell)) {
            narrow.add(cell);
          }
        }
      }
      if (narrow.isEmpty) {
        return;
      }
      for (Cell cell in narrow) {
        for (int dx = -1; dx <= 1; dx++) {
          for (int dy = -1; dy <= 1; dy++) {
            Cell around = Cell(cell.x + dx, cell.y + dy);
            if (map.isInside(around)) {
              _buildWalkablePassage(map, around);
            }
          }
        }
      }
    }
  }

  // Whether the cell is a corner of a block of 2 x 2 cells of walkable land.
  bool _inWalkableSquare(TerrainMap map, Cell cell) {
    for (int dx = -1; dx <= 0; dx++) {
      for (int dy = -1; dy <= 0; dy++) {
        if (isWalkableLand(map, Cell(cell.x + dx, cell.y + dy)) &&
            isWalkableLand(map, Cell(cell.x + dx + 1, cell.y + dy)) &&
            isWalkableLand(map, Cell(cell.x + dx, cell.y + dy + 1)) &&
            isWalkableLand(map, Cell(cell.x + dx + 1, cell.y + dy + 1))) {
          return true;
        }
      }
    }
    return false;
  }

  // Makes a cell walkable land: water becomes soil, a high peak becomes medium.
  void _buildWalkablePassage(TerrainMap map, Cell cell) {
    if (!isSoil(map, cell) && map.groundAt(cell) != BeachModel) {
      map.setGround(cell, SoilModel);
    }
    if (map.heightAreaAt(cell) == HeightAreaHighModel) {
      map.setHeightArea(cell, HeightAreaMediumModel);
    }
  }
}
