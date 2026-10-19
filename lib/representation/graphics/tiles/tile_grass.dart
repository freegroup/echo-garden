import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_ground.dart';
import 'package:echo_garden/representation/world_view.dart';

/// Grass, a soft cover on the ground.
class TileGrass extends TileGround {
  TileGrass() : super(imageNames: ['grass-05.png', 'grass-06.png', 'grass-07.png']);

  @override
  bool covers(WorldView worldView, int x, int y) => coversPlant(worldView, x, y, GrassModel);
}
