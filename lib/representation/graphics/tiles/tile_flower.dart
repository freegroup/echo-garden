import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_plant.dart';
import 'package:echo_garden/representation/world_view.dart';

/// Flowers. A young flower is hardly to be seen; the more energy it has, the
/// more it shows, fully at its full energy.
class TileFlower extends TilePlant {
  TileFlower() : super(type: FlowerModel, imageNames: ['flower-01.png', 'flower-02.png']);

  @override
  double opacityFor(AgentView plant) {
    var flower = kGameConfiguration.plant.flower;
    double normalized = (plant.energy - flower.initialEnergy) / (flower.maxEnergy - flower.initialEnergy);
    return normalized.clamp(0.0, 1.0);
  }
}
