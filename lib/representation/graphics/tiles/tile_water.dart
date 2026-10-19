import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_ground.dart';
import 'package:echo_garden/representation/world_view.dart';

/// Deep water, the lowest ground.
class TileWater extends TileGround {
  TileWater() : super(imageNames: ['water-01.png', 'water-02.png']);

  @override
  bool covers(WorldView worldView, int x, int y) => coversTerrain(worldView, x, y, WaterModel);
}
