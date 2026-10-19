import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_plant.dart';
import 'package:echo_garden/representation/world_view.dart';

/// Oaks. A tree grows through its images, from the energy it starts with up
/// to its full energy. Whether it is mirrored is fixed by its cell, so a tree
/// always looks the same.
class TileTree extends TilePlant {
  // how this kind of tree grows (from the configuration)
  final TreeSettings settings;

  TileTree({
    super.type = TreeModel,
    TreeSettings? settings,
    super.imageNames = const ['tree-01.png', 'tree-02.png', 'tree-03.png', 'tree-04.png'],
  }) : settings = settings ?? kGameConfiguration.plant.tree;

  @override
  int imageIndexFor(AgentView plant) {
    return growthStage(plant.energy, settings.initialEnergy, settings.maxEnergy, imageNames.length);
  }

  @override
  bool mirroredFor(AgentView plant) => everyOtherCell(plant.cell);
}
