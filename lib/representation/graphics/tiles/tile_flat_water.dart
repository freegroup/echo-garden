import 'package:echo_garden/model/objects/flat_water.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_ground.dart';
import 'package:echo_garden/representation/world_view.dart';

/// Flat water in front of the beaches.
class TileFlatWater extends TileGround {
  TileFlatWater() : super(imageNames: ['water-beach-01.png', 'water-beach-02.png']);

  @override
  bool covers(WorldView worldView, int x, int y) => coversTerrain(worldView, x, y, FlatWaterModel);
}
