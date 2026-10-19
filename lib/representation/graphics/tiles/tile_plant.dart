import 'dart:ui' as ui;

import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/representation/graphics/tiles/tile.dart';
import 'package:echo_garden/representation/world_view.dart';
import 'package:flame/cache.dart';
import 'package:flutter/painting.dart';

/// A tile of a plant: on every cell where a plant of [type] stands, one of the
/// images, over the ground. Which image, how opaque and whether mirrored
/// follows from the plant's state; a plant type decides that by overriding
/// the methods below.
abstract class TilePlant extends Tile {
  final Type type;
  final List<String> imageNames;

  late final List<ui.Image> _images;

  TilePlant({required this.type, required this.imageNames});

  /// Which of the images the plant shows: by default a variant fixed by its cell.
  int imageIndexFor(AgentView plant) => variantAt(plant.cell.x, plant.cell.y, imageNames.length);

  /// How opaque the plant is drawn, 0..1: by default fully.
  double opacityFor(AgentView plant) => 1;

  /// Whether the plant is drawn mirrored: by default not.
  bool mirroredFor(AgentView plant) => false;

  // ---- tools for the plant tiles ----

  /// The image of a growing plant: from the first one at [minEnergy] to the
  /// last one at [maxEnergy], in [count] steps.
  int growthStage(double energy, double minEnergy, double maxEnergy, int count) {
    double value = energy.clamp(minEnergy, maxEnergy);
    double normalized = (value - minEnergy) / (maxEnergy - minEnergy);
    return ((count - 1) * normalized).round().clamp(0, count - 1);
  }

  /// A fixed choice for a cell, half of the cells yes and half no.
  bool everyOtherCell(Cell cell) => (cell.x * 31 + cell.y * 17) % 2 == 1;

  // ---- drawing ----

  @override
  Future<void> load(Images images) async {
    _images = await loadImages(images, imageNames);
  }

  @override
  void render(Canvas canvas, WorldView worldView, Rect view) {
    int x0 = (view.left / Tile.size).floor();
    int x1 = (view.right / Tile.size).ceil();
    int y0 = (view.top / Tile.size).floor();
    int y1 = (view.bottom / Tile.size).ceil();

    for (int y = y0; y <= y1; y++) {
      for (int x = x0; x <= x1; x++) {
        AgentView? plant = worldView.agentAt(Cell(x, y), PlantModel.staticLayerId);
        if (plant == null || plant.type != type) continue;
        _drawPlant(canvas, plant, x, y);
      }
    }
  }

  void _drawPlant(Canvas canvas, AgentView plant, int x, int y) {
    double opacity = opacityFor(plant);
    if (opacity <= 0) return;

    ui.Image image = _images[imageIndexFor(plant)];
    Rect source = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    Rect cell = Rect.fromLTWH(x * Tile.size.toDouble(), y * Tile.size.toDouble(),
        Tile.size.toDouble(), Tile.size.toDouble());
    paint.color = Color.fromRGBO(255, 255, 255, opacity);

    if (mirroredFor(plant)) {
      // mirror around the middle of the cell
      canvas.save();
      canvas.translate(cell.center.dx, 0);
      canvas.scale(-1, 1);
      canvas.translate(-cell.center.dx, 0);
      canvas.drawImageRect(image, source, cell, paint);
      canvas.restore();
    } else {
      canvas.drawImageRect(image, source, cell, paint);
    }
  }
}
