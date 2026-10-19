import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_tree.dart';

/// Pines: they grow like the oaks, with their own images and settings.
class TilePine extends TileTree {
  TilePine()
      : super(
          type: PineModel,
          settings: kGameConfiguration.plant.pine,
          imageNames: ['pine-01.png', 'pine-02.png', 'pine-03.png', 'pine-04.png'],
        );
}
