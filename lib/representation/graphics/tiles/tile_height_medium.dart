import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_ground.dart';
import 'package:echo_garden/representation/world_view.dart';

/// Medium mountains.
class TileHeightMedium extends TileGround {
  TileHeightMedium() : super(imageNames: ['height-medium-01.png', 'height-medium-02.png']);

  @override
  bool covers(WorldView worldView, int x, int y) => coversTerrain(worldView, x, y, HeightAreaMediumModel);
}
