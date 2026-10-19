import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_ground.dart';
import 'package:echo_garden/representation/world_view.dart';

/// Low hills.
class TileHeightLow extends TileGround {
  TileHeightLow() : super(imageNames: ['height-low-01.png', 'height-low-02.png']);

  @override
  bool covers(WorldView worldView, int x, int y) => coversTerrain(worldView, x, y, HeightAreaLowModel);
}
