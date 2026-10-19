import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/terraformer/terraform_plugin.dart';
import 'package:echo_garden/model/terraformer/terrain_map.dart';

/// The highest cells become mountains: the very highest are high, around them
/// medium and then low. The height map is smooth, so the peaks end up in the
/// middle of the mountain areas.
///
/// Mountains stand where the heights put them, whatever the ground below: on a
/// beach they make a steep coast, on a piece of land that is flooded later they
/// stand in the water.
class TerraformMountains extends TerraformPlugin {
  @override
  void phase00Generate(TerrainMap map) {
    var mountain = kGameConfiguration.mountain;
    List<double> sorted = sortedHeights(map);
    double highThreshold = _heightAbovePercentage(sorted, mountain.highPercentage);
    double mediumThreshold =
        _heightAbovePercentage(sorted, mountain.highPercentage + mountain.mediumPercentage);
    double lowThreshold = _heightAbovePercentage(
        sorted, mountain.highPercentage + mountain.mediumPercentage + mountain.lowPercentage);

    for (int x = 0; x < map.width; x++) {
      for (int y = 0; y < map.height; y++) {
        Cell cell = Cell(x, y);
        double cellHeight = map.heights[x][y];
        if (cellHeight >= highThreshold) {
          map.setHeightArea(cell, HeightAreaHighModel);
        } else if (cellHeight >= mediumThreshold) {
          map.setHeightArea(cell, HeightAreaMediumModel);
        } else if (cellHeight >= lowThreshold) {
          map.setHeightArea(cell, HeightAreaLowModel);
        }
      }
    }
  }

  // The height that only the given percentage of the map lies above.
  double _heightAbovePercentage(List<double> sorted, double percentage) {
    int index = (sorted.length * (1 - percentage / 100.0)).floor();
    index = index.clamp(0, sorted.length - 1);
    return sorted[index];
  }
}
