import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/objects/beach.dart';
import 'package:echo_garden/model/objects/flat_water.dart';
import 'package:echo_garden/representation/graphics/tiles/tile.dart';
import 'package:echo_garden/representation/world_view.dart';
import 'package:flame/cache.dart';
import 'package:flutter/painting.dart';

/// A tile of the ground, drawn with smooth transitions (dual-grid autotiling).
///
/// The display tiles sit on a grid offset by half a cell: each one covers the
/// corner where four cells meet. Which of those four cells the ground covers
/// gives a 4-bit mask, and the matching rounded piece is drawn. The 16 mask
/// shapes are made once for all ground tiles. The ground tiles are drawn from
/// low to high (see TileRenderer), so a higher one always rounds over the one
/// below.
abstract class TileGround extends Tile {
  final List<String> imageNames;

  // multiplied into the images, e.g. to make green grass look dry
  final Color? tint;

  late final List<ui.Image> _variants;
  final List<ui.Image?> _edge = List.filled(16, null); // _edge[mask] for mask 1..14

  TileGround({required this.imageNames, this.tint});

  /// Whether this ground covers the cell (x, y).
  bool covers(WorldView worldView, int x, int y);

  // ---- tools for the ground tiles ----

  /// The terrains from low to high.
  static const List<Type> terrainOrder = [
    WaterModel,
    FlatWaterModel,
    BeachModel,
    SoilModel,
    HeightAreaLowModel,
    HeightAreaMediumModel,
    HeightAreaHighModel,
  ];

  /// For the terrains: a cell is covered by [type] when its own ground is
  /// [type] or a higher one, so a higher terrain lies on top of a lower one.
  /// Beyond the edge of the map the cell at the edge counts.
  bool coversTerrain(WorldView worldView, int x, int y, Type type) {
    x = x.clamp(0, worldView.width - 1);
    y = y.clamp(0, worldView.height - 1);
    int rank = terrainOrder.indexOf(worldView.groundTypeAt(Cell(x, y)) ?? WaterModel);
    if (rank < 0) rank = 0;
    return rank >= terrainOrder.indexOf(type);
  }

  /// For the ground cover: whether a plant of [type] stands on the cell.
  bool coversPlant(WorldView worldView, int x, int y, Type type) {
    return worldView.agentAt(Cell(x, y), PlantModel.staticLayerId)?.type == type;
  }

  // ---- drawing ----

  @override
  Future<void> load(Images images) async {
    List<ui.Image> masks = await (_masks ??= _buildMasks());
    List<ui.Image> textures = await loadImages(images, imageNames);
    Color? tintColor = tint;
    _variants = tintColor == null ? textures : [for (ui.Image t in textures) await _tinted(t, tintColor)];

    // the rounded edge pieces use the first variant masked by each shape
    for (int mask = 1; mask <= 14; mask++) {
      _edge[mask] = await _applyMask(_variants.first, masks[mask]);
    }
  }

  @override
  void render(Canvas canvas, WorldView worldView, Rect view) {
    // the display grid is offset by half a tile, so look one tile wider
    int cornerX0 = (view.left / Tile.size).floor();
    int cornerX1 = (view.right / Tile.size).ceil() + 1;
    int cornerY0 = (view.top / Tile.size).floor();
    int cornerY1 = (view.bottom / Tile.size).ceil() + 1;

    for (int cornerY = cornerY0; cornerY <= cornerY1; cornerY++) {
      for (int cornerX = cornerX0; cornerX <= cornerX1; cornerX++) {
        int mask = 0;
        if (covers(worldView, cornerX - 1, cornerY - 1)) mask |= 1; // top left
        if (covers(worldView, cornerX, cornerY - 1)) mask |= 2; // top right
        if (covers(worldView, cornerX - 1, cornerY)) mask |= 4; // bottom left
        if (covers(worldView, cornerX, cornerY)) mask |= 8; // bottom right
        if (mask == 0) continue;

        // fully covered: a full tile, its variant fixed by the position
        ui.Image image = mask == 15
            ? _variants[variantAt(cornerX, cornerY, _variants.length)]
            : _edge[mask]!;
        _drawTile(canvas, image, (cornerX - 0.5) * Tile.size, (cornerY - 0.5) * Tile.size);
      }
    }
  }

  // Draws a tile one pixel larger than its cell, so neighboring tiles overlap.
  // Without this overlap, the camera's smooth (sub-pixel) scrolling leaves a
  // thin seam between tiles that shows up as a flickering grid.
  static const Rect _tileSource = Rect.fromLTWH(0, 0, 64, 64); // one tile, 64x64

  void _drawTile(Canvas canvas, ui.Image image, double left, double top) {
    Rect dst = Rect.fromLTWH(left, top, Tile.size + 1.0, Tile.size + 1.0);
    canvas.drawImageRect(image, _tileSource, dst, paint);
  }

  // ---- the 16 masks, made once for all ground tiles ----

  static Future<List<ui.Image>>? _masks;

  // Builds a 64x64 alpha mask for each of the 16 corner combinations. A pixel
  // belongs to the ground when it is close enough to the covered corners (a
  // metaball shape), which gives round outer and inner corners.
  static Future<List<ui.Image>> _buildMasks() async {
    const corners = [Offset(0, 0), Offset(1, 0), Offset(0, 1), Offset(1, 1)];
    const double radius = 0.95;
    const int size = Tile.size;

    List<ui.Image> masks = [];
    for (int mask = 0; mask < 16; mask++) {
      Uint8List pixels = Uint8List(size * size * 4);
      for (int py = 0; py < size; py++) {
        for (int px = 0; px < size; px++) {
          double u = (px + 0.5) / size;
          double v = (py + 0.5) / size;
          double sum = 0;
          for (int corner = 0; corner < 4; corner++) {
            if ((mask >> corner) & 1 == 1) {
              double dx = u - corners[corner].dx;
              double dy = v - corners[corner].dy;
              double value = 1 - (dx * dx + dy * dy) / (radius * radius);
              if (value > 0) sum += value;
            }
          }
          int offset = (py * size + px) * 4;
          int alpha = sum >= 0.5 ? 255 : 0;
          pixels[offset] = 255;
          pixels[offset + 1] = 255;
          pixels[offset + 2] = 255;
          pixels[offset + 3] = alpha;
        }
      }
      masks.add(await _imageFromPixels(pixels, size, size));
    }
    return masks;
  }

  static Future<ui.Image> _imageFromPixels(Uint8List pixels, int width, int height) {
    Completer<ui.Image> completer = Completer();
    ui.decodeImageFromPixels(pixels, width, height, ui.PixelFormat.rgba8888, completer.complete);
    return completer.future;
  }

  // Combines a texture with a mask: the texture is kept only where the mask
  // is opaque.
  Future<ui.Image> _applyMask(ui.Image texture, ui.Image mask) {
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);
    canvas.drawImage(texture, Offset.zero, Paint());
    canvas.drawImage(mask, Offset.zero, Paint()..blendMode = BlendMode.dstIn);
    return recorder.endRecording().toImage(Tile.size, Tile.size);
  }

  // Multiplies a texture with a color.
  Future<ui.Image> _tinted(ui.Image texture, Color color) {
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);
    canvas.drawImage(texture, Offset.zero, Paint());
    canvas.drawColor(color, BlendMode.modulate);
    return recorder.endRecording().toImage(Tile.size, Tile.size);
  }
}
