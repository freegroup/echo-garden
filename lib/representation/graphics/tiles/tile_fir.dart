import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_tree.dart';

/// Firs: they grow like the oaks, with their own images and settings.
class TileFir extends TileTree {
  TileFir()
      : super(
          type: FirModel,
          settings: kGameConfiguration.plant.fir,
          imageNames: ['fir-01.png', 'fir-02.png', 'fir-03.png', 'fir-04.png'],
        );
}
