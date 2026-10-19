import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/terraformer/terraform_plugin.dart';
import 'package:echo_garden/model/terraformer/terrain_map.dart';

/// One connected land: small pieces of land become water, bigger ones get a
/// land bridge to the largest one.
class TerraformIslands extends TerraformPlugin {
  @override
  void phase02Connect(TerrainMap map) {
    _floodSmallIslands(map);
    connectRegions(map, (cell) => isSoil(map, cell), (cell) => _buildLandBridge(map, cell));
  }

  // Land pieces that are too small for a bridge become water.
  void _floodSmallIslands(TerrainMap map) {
    List<Set<Cell>> regions = findRegions(map, (cell) => isSoil(map, cell));
    if (regions.isEmpty) {
      return;
    }
    Set<Cell> mainLand = largest(regions);
    for (Set<Cell> region in regions) {
      if (region != mainLand && region.length < kGameConfiguration.world.minIslandSize) {
        for (Cell cell in region) {
          map.setGround(cell, WaterModel);
        }
      }
    }
  }

  // A land bridge three cells wide. One cell wide would turn into water again
  // when the beaches are made; this way it gets sandy edges and soil inside.
  void _buildLandBridge(TerrainMap map, Cell center) {
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        Cell cell = Cell(center.x + dx, center.y + dy);
        if (map.isInside(cell) && !isSoil(map, cell)) {
          map.setGround(cell, SoilModel);
        }
      }
    }
  }
}
