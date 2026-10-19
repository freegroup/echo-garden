import 'package:echo_garden/representation/graphics/game.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_beach.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_fir.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_flat_water.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_flower.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_grass.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_height_high.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_height_low.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_height_medium.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_parched_grass.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_pine.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_soil.dart';
import 'package:echo_garden/representation/graphics/tiles/tile.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_tree.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_water.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_weed.dart';
import 'package:echo_garden/representation/world_view.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// Draws all tiles (see Tile), one after the other over the visible cells:
/// first the ground from low to high, so a higher ground rounds over a lower
/// one, then the grass, then the plants. The sprites (rabbits, the player)
/// are drawn above.
class TileRenderer extends PositionComponent with HasGameReference<GameVisualization> {
  final WorldView worldView;

  // in the order they are drawn
  final List<Tile> tiles = [
    TileWater(),
    TileFlatWater(),
    TileBeach(),
    TileSoil(),
    TileHeightLow(),
    TileHeightMedium(),
    TileHeightHigh(),
    TileParchedGrass(),
    TileGrass(),
    TileWeed(),
    TileFlower(),
    TileTree(),
    TileFir(),
    TilePine(),
  ];

  bool _ready = false;

  TileRenderer({required this.worldView});

  @override
  Future<void> onLoad() async {
    for (Tile tile in tiles) {
      await tile.load(game.images);
    }
    _ready = true;
  }

  @override
  void render(Canvas canvas) {
    if (!_ready) return;
    Rect view = game.cameraComponent.visibleWorldRect;
    for (Tile tile in tiles) {
      tile.render(canvas, worldView, view);
    }
  }
}
