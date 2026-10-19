import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_ground.dart';
import 'package:echo_garden/representation/world_view.dart';

/// Soil: the land where plants grow.
class TileSoil extends TileGround {
  TileSoil() : super(imageNames: ['soil-01.png', 'soil-02.png']);

  @override
  bool covers(WorldView worldView, int x, int y) => coversTerrain(worldView, x, y, SoilModel);
}
