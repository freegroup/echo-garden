import 'package:echo_garden/model/objects/parched_grass.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_ground.dart';
import 'package:echo_garden/representation/world_view.dart';
import 'package:flutter/painting.dart';

/// Parched grass: the grass images, tinted dry and yellow.
class TileParchedGrass extends TileGround {
  TileParchedGrass() : super(imageNames: ['grass-05.png', 'grass-06.png', 'grass-07.png'], tint: const Color(0xFFAEA24B));

  @override
  bool covers(WorldView worldView, int x, int y) => coversPlant(worldView, x, y, ParchedGrassModel);
}
