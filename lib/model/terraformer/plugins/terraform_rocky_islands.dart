import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/objects/flat_water.dart';
import 'package:echo_garden/model/terraformer/terraform_plugin.dart';
import 'package:echo_garden/model/terraformer/terrain_map.dart';

/// A few round rocky islands in open water, away from the shore. They stay out
/// of reach on purpose.
class TerraformRockyIslands extends TerraformPlugin {
  @override
  void phase03Areas(TerrainMap map) {
    var mountain = kGameConfiguration.mountain;
    int placed = 0;
    for (int attempt = 0; attempt < 500 && placed < mountain.islandCount; attempt++) {
      Cell center = Cell(map.random.nextInt(map.width), map.random.nextInt(map.height));
      // one cell of water more than the widest rim, so the island never touches land
      if (_isOpenWater(map, center, mountain.islandLowRadius + 1.6)) {
        _placeIsland(map, center);
        placed++;
      }
    }
  }

  // True if every cell within the radius is water without a height area.
  bool _isOpenWater(TerrainMap map, Cell center, double radius) {
    int range = radius.ceil();
    for (int dx = -range; dx <= range; dx++) {
      for (int dy = -range; dy <= range; dy++) {
        Cell cell = Cell(center.x + dx, center.y + dy);
        if (center.distanceTo(cell) > radius) {
          continue;
        }
        // cells outside of the map have no ground, so they are no water
        Type? ground = map.groundAt(cell);
        bool isWater = ground == WaterModel || ground == FlatWaterModel;
        if (!isWater || map.heightAreaAt(cell) != null) {
          return false;
        }
      }
    }
    return true;
  }

  void _placeIsland(TerrainMap map, Cell center) {
    var mountain = kGameConfiguration.mountain;
    int range = (mountain.islandLowRadius + 1).ceil();
    for (int dx = -range; dx <= range; dx++) {
      for (int dy = -range; dy <= range; dy++) {
        Cell cell = Cell(center.x + dx, center.y + dy);
        double distance = center.distanceTo(cell);
        // the rim is a bit uneven, so the island does not look like a circle
        double rim = mountain.islandLowRadius + map.random.nextDouble() * 0.6;
        if (distance <= mountain.islandHighRadius) {
          map.setHeightArea(cell, HeightAreaHighModel);
        } else if (distance <= mountain.islandMediumRadius) {
          map.setHeightArea(cell, HeightAreaMediumModel);
        } else if (distance <= rim) {
          map.setHeightArea(cell, HeightAreaLowModel);
        }
      }
    }
  }
}
