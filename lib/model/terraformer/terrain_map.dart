import 'dart:math';

import 'package:echo_garden/model/index.dart';

/// The map the terraform plugins work on, before anything is in the model.
///
/// Per cell a ground (WaterModel, FlatWaterModel, BeachModel or SoilModel) and
/// maybe a height area on it (HeightAreaLowModel, ...MediumModel, ...HighModel).
/// The types of the model are the vocabulary, as in the world view; only at
/// the end the terraformer turns the map into model objects.
class TerrainMap {
  final int width;
  final int height;

  // the random numbers of all plugins, from the seed: the same seed gives the
  // same map
  final Random random;

  // the numbers the generator made in phase00Generate; the plugins read them
  // to decide what lies where. The grid may be bigger than the map.
  late List<List<double>> heights;

  // empty until the plugins of phase00Generate fill it
  final List<List<Type?>> _ground;
  final List<List<Type?>> _heightAreas;

  TerrainMap({required this.width, required this.height, required this.random})
      : _ground = List.generate(width, (_) => List<Type?>.filled(height, null)),
        _heightAreas = List.generate(width, (_) => List<Type?>.filled(height, null));

  bool isInside(Cell cell) {
    return cell.x >= 0 && cell.y >= 0 && cell.x < width && cell.y < height;
  }

  /// The ground of a cell; null outside of the map and where there is none yet.
  Type? groundAt(Cell cell) => isInside(cell) ? _ground[cell.x][cell.y] : null;

  void setGround(Cell cell, Type ground) {
    _ground[cell.x][cell.y] = ground;
  }

  /// The height area on a cell, or null.
  Type? heightAreaAt(Cell cell) => isInside(cell) ? _heightAreas[cell.x][cell.y] : null;

  void setHeightArea(Cell cell, Type? heightArea) {
    _heightAreas[cell.x][cell.y] = heightArea;
  }

  /// The topmost type of a cell, as GameModel.groundTypeAt: the height area,
  /// else the ground. Null outside of the map.
  Type? groundTypeAt(Cell cell) => heightAreaAt(cell) ?? groundAt(cell);
}
