import 'dart:ui' as ui;

import 'package:echo_garden/representation/world_view.dart';
import 'package:flame/cache.dart';
import 'package:flutter/painting.dart';

/// Draws one type of the world that needs no memory: what a cell shows
/// follows from the world view right now (its ground, its plant, the plant's
/// energy), e.g. water, grass or a tree. One tile draws all cells of its type,
/// so it holds no state per cell, only its images.
///
/// What moves between cells or is animated needs a memory: it is a sprite
/// (see sprites/), not a tile.
abstract class Tile {
  // pixels per cell; must match world.tileSize
  static const int size = 64;

  /// Loads the images, once, before the first render.
  Future<void> load(Images images);

  /// Draws the type in the cells that lie in [view] (in pixels of the world).
  void render(Canvas canvas, WorldView worldView, Rect view);

  /// A variant for a cell that never changes, so the same cell always looks
  /// the same, also after it was out of sight.
  int variantAt(int x, int y, int count) => (x * 7 + y * 13) % count;

  /// Loads the images with these names.
  Future<List<ui.Image>> loadImages(Images images, List<String> names) async {
    return [for (String name in names) await images.load(name)];
  }

  // pixel art: no smoothing
  final Paint paint = Paint()
    ..isAntiAlias = false
    ..filterQuality = FilterQuality.none;
}
