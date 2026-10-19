import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:echo_garden/representation/graphics/game.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/objects/beach.dart';
import 'package:echo_garden/model/objects/flat_water.dart';
import 'package:echo_garden/model/objects/parched_grass.dart';
import 'package:echo_garden/representation/world_view.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// True for agents that the GroundRenderer draws as a soft ground layer
/// (grass), so the per-agent renderer skips them.
bool isGroundCover(AgentView agent) => agent.type == GrassModel || agent.type == ParchedGrassModel;

/// Draws the ground with smooth transitions (dual-grid autotiling).
///
/// The display tiles sit on a grid offset by half a cell: each one covers the
/// corner where four world cells meet. For every ground layer it builds a
/// 4-bit mask from those four corners (which of them the layer covers) and
/// draws the matching rounded transition. The 16 mask shapes are generated
/// once. The layers are drawn from bottom to top, so a higher layer always
/// rounds over the one below.
///
/// Layers are the terrains (water → beach → soil → mountains) plus the ground
/// cover (grass), which may lie on any terrain. This only reads the model.
class GroundRenderer extends PositionComponent with HasGameReference<GameVisualization> {
  final WorldView worldView;

  GroundRenderer({required this.worldView});

  static const int _tile = 64; // pixels per tile; must match world.tileSize

  late final List<_GroundLayer> _layers;
  bool _ready = false;

  @override
  Future<void> onLoad() async {
    List<ui.Image> masks = await _buildMasks();

    // the terrains, from low to high; a cell is covered by terrain of rank r
    // when its own ground rank is r or higher
    List<Type> terrainOrder = [
      WaterModel,
      FlatWaterModel,
      BeachModel,
      SoilModel,
      HeightAreaLowModel,
      HeightAreaMediumModel,
      HeightAreaHighModel,
    ];
    Map<Type, int> rankOf = {for (int i = 0; i < terrainOrder.length; i++) terrainOrder[i]: i};
    List<List<String>> terrainImages = [
      ['water-01', 'water-02'],
      ['water-beach-01', 'water-beach-02'],
      ['beach-01', 'beach-02'],
      ['soil-01', 'soil-02'],
      ['height-low-01', 'height-low-02'],
      ['height-medium-01', 'height-medium-02'],
      ['height-high-01', 'height-high-02'],
    ];

    int rankAt(int x, int y) {
      x = x.clamp(0, worldView.width - 1);
      y = y.clamp(0, worldView.height - 1);
      return rankOf[worldView.groundTypeAt(Cell(x, y))] ?? 0;
    }

    _layers = [];
    for (int rank = 0; rank < terrainOrder.length; rank++) {
      _layers.add(await _buildLayer(
        masks,
        await _loadImages(terrainImages[rank]),
        (x, y) => rankAt(x, y) >= rank,
      ));
    }

    // ground cover on top of the terrain: grass, and dry (parched) grass
    bool hasGrass(int x, int y) => _plantAt(x, y)?.type == GrassModel;
    bool hasParched(int x, int y) => _plantAt(x, y)?.type == ParchedGrassModel;

    List<ui.Image> grass = await _loadImages(['grass-05', 'grass-06', 'grass-07']);
    _layers.add(await _buildLayer(masks, grass, hasParched, tint: const Color(0xFFAEA24B)));
    _layers.add(await _buildLayer(masks, grass, hasGrass));

    _ready = true;
  }

  // Loads the images, fetching any that were not preloaded.
  Future<List<ui.Image>> _loadImages(List<String> names) async {
    List<ui.Image> images = [];
    for (String name in names) {
      images.add(await game.images.load('$name.png'));
    }
    return images;
  }


  AgentView? _plantAt(int x, int y) {
    if (x < 0 || y < 0 || x >= worldView.width || y >= worldView.height) return null;
    return worldView.agentAt(Cell(x, y), PlantModel.staticLayerId);
  }

  @override
  void render(Canvas canvas) {
    if (!_ready) return;

    Rect view = game.cameraComponent.visibleWorldRect;
    // the display grid is offset by half a tile, so look one tile wider
    int cornerX0 = (view.left / _tile).floor();
    int cornerX1 = (view.right / _tile).ceil() + 1;
    int cornerY0 = (view.top / _tile).floor();
    int cornerY1 = (view.bottom / _tile).ceil() + 1;

    for (int cornerY = cornerY0; cornerY <= cornerY1; cornerY++) {
      for (int cornerX = cornerX0; cornerX <= cornerX1; cornerX++) {
        _drawDisplayTile(canvas, cornerX, cornerY);
      }
    }
  }

  void _drawDisplayTile(Canvas canvas, int cornerX, int cornerY) {
    double left = (cornerX - 0.5) * _tile;
    double top = (cornerY - 0.5) * _tile;

    for (_GroundLayer layer in _layers) {
      int mask = 0;
      if (layer.covered(cornerX - 1, cornerY - 1)) mask |= 1; // top left
      if (layer.covered(cornerX, cornerY - 1)) mask |= 2; // top right
      if (layer.covered(cornerX - 1, cornerY)) mask |= 4; // bottom left
      if (layer.covered(cornerX, cornerY)) mask |= 8; // bottom right

      if (mask == 0) continue;
      if (mask == 15) {
        // fully covered: a full tile, variant chosen stably by position
        List<ui.Image> variants = layer.variants;
        ui.Image full = variants[(cornerX * 7 + cornerY * 13) % variants.length];
        _drawTile(canvas, full, left, top);
      } else {
        _drawTile(canvas, layer.edge[mask]!, left, top);
      }
    }
  }

  // Draws a tile one pixel larger than its cell, so neighboring tiles overlap.
  // Without this overlap, the camera's smooth (sub-pixel) scrolling leaves a
  // thin seam between tiles that shows up as a flickering grid.
  final Paint _tilePaint = Paint()
    ..isAntiAlias = false
    ..filterQuality = FilterQuality.none;
  static const Rect _tileSource = Rect.fromLTWH(0, 0, 64, 64); // one tile, 64x64

  void _drawTile(Canvas canvas, ui.Image image, double left, double top) {
    Rect dst = Rect.fromLTWH(left, top, _tile + 1.0, _tile + 1.0);
    canvas.drawImageRect(image, _tileSource, dst, _tilePaint);
  }

  // ---- building the layers and the 16 masks, once ----

  Future<_GroundLayer> _buildLayer(
    List<ui.Image> masks,
    List<ui.Image> textures,
    bool Function(int x, int y) covered, {
    Color? tint,
  }) async {
    List<ui.Image> variants = textures;
    if (tint != null) {
      variants = [for (ui.Image t in textures) await _tinted(t, tint)];
    }
    // the rounded edge pieces use the first variant masked by each shape
    List<ui.Image?> edge = List.filled(16, null);
    for (int mask = 1; mask <= 14; mask++) {
      edge[mask] = await _applyMask(variants.first, masks[mask]);
    }
    return _GroundLayer(variants: variants, edge: edge, covered: covered);
  }

  // Builds a 64x64 alpha mask for each of the 16 corner combinations. A pixel
  // belongs to the layer when it is close enough to the covered corners (a
  // metaball shape), which gives round outer and inner corners.
  Future<List<ui.Image>> _buildMasks() async {
    const corners = [Offset(0, 0), Offset(1, 0), Offset(0, 1), Offset(1, 1)];
    const double radius = 0.95;

    List<ui.Image> masks = [];
    for (int mask = 0; mask < 16; mask++) {
      Uint8List pixels = Uint8List(_tile * _tile * 4);
      for (int py = 0; py < _tile; py++) {
        for (int px = 0; px < _tile; px++) {
          double u = (px + 0.5) / _tile;
          double v = (py + 0.5) / _tile;
          double sum = 0;
          for (int corner = 0; corner < 4; corner++) {
            if ((mask >> corner) & 1 == 1) {
              double dx = u - corners[corner].dx;
              double dy = v - corners[corner].dy;
              double value = 1 - (dx * dx + dy * dy) / (radius * radius);
              if (value > 0) sum += value;
            }
          }
          int offset = (py * _tile + px) * 4;
          int alpha = sum >= 0.5 ? 255 : 0;
          pixels[offset] = 255;
          pixels[offset + 1] = 255;
          pixels[offset + 2] = 255;
          pixels[offset + 3] = alpha;
        }
      }
      masks.add(await _imageFromPixels(pixels, _tile, _tile));
    }
    return masks;
  }

  Future<ui.Image> _imageFromPixels(Uint8List pixels, int width, int height) {
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
    return recorder.endRecording().toImage(_tile, _tile);
  }

  // Multiplies a texture with a color, e.g. to make green grass look dry.
  Future<ui.Image> _tinted(ui.Image texture, Color color) {
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);
    canvas.drawImage(texture, Offset.zero, Paint());
    canvas.drawColor(color, BlendMode.modulate);
    return recorder.endRecording().toImage(_tile, _tile);
  }
}

class _GroundLayer {
  final List<ui.Image> variants;
  final List<ui.Image?> edge; // edge[mask] for mask 1..14
  final bool Function(int x, int y) covered;

  _GroundLayer({required this.variants, required this.edge, required this.covered});
}
