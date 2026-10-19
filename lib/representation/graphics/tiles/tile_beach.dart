import 'package:echo_garden/model/objects/beach.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_ground.dart';
import 'package:echo_garden/representation/world_view.dart';

/// Sandy beaches at the water.
class TileBeach extends TileGround {
  TileBeach() : super(imageNames: ['beach-01.png', 'beach-02.png']);

  @override
  bool covers(WorldView worldView, int x, int y) => coversTerrain(worldView, x, y, BeachModel);
}
