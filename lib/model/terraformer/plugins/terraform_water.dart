import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/terraformer/terraform_plugin.dart';
import 'package:echo_garden/model/terraformer/terrain_map.dart';

/// Water and land: the lowest part of the map becomes water, the rest soil.
class TerraformWater extends TerraformPlugin {
  @override
  void phase00Generate(TerrainMap map) {
    List<double> sorted = sortedHeights(map);
    int waterIndex =
        (sorted.length * (kGameConfiguration.world.waterPercentage / 100.0)).floor();
    double waterThreshold = sorted[waterIndex];

    for (int x = 0; x < map.width; x++) {
      for (int y = 0; y < map.height; y++) {
        bool isWater = map.heights[x][y] < waterThreshold;
        map.setGround(Cell(x, y), isWater ? WaterModel : SoilModel);
      }
    }
  }
}
