import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_ground.dart';
import 'package:echo_garden/representation/world_view.dart';

/// High mountains with snow, the highest ground.
class TileHeightHigh extends TileGround {
  TileHeightHigh() : super(imageNames: ['height-high-01.png', 'height-high-02.png']);

  @override
  bool covers(WorldView worldView, int x, int y) => coversTerrain(worldView, x, y, HeightAreaHighModel);
}
