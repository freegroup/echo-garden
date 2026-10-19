import 'dart:math';

import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/objects/beach.dart';
import 'package:echo_garden/model/objects/flat_water.dart';
import 'package:echo_garden/model/terraformer/plugins/terraform_air.dart';
import 'package:echo_garden/model/terraformer/plugins/terraform_coast.dart';
import 'package:echo_garden/model/terraformer/plugins/terraform_diamond_square.dart';
import 'package:echo_garden/model/terraformer/plugins/terraform_islands.dart';
import 'package:echo_garden/model/terraformer/plugins/terraform_mountains.dart';
import 'package:echo_garden/model/terraformer/plugins/terraform_passages.dart';
import 'package:echo_garden/model/terraformer/plugins/terraform_rocky_islands.dart';
import 'package:echo_garden/model/terraformer/plugins/terraform_water.dart';
import 'package:echo_garden/model/terraformer/terraform_plugin.dart';
import 'package:echo_garden/model/terraformer/terrain_map.dart';

/// Shapes the landscape of a new model: water and land, beaches, mountains,
/// rocky islands in the sea, and the air above. All land the player can walk
/// on is connected.
///
/// The terraformer is a pipeline of plugins (see TerraformPlugin), each with
/// one task. It runs them phase by phase on a map of its own, then puts the
/// finished ground into the model and lets them populate it.
class Terraformer {
  final GameModel model;
  final Random _random;

  // In this order in every phase. The generator comes first: another
  // generator can take its place.
  final List<TerraformPlugin> plugins = [
    TerraformDiamondSquare(),
    TerraformWater(),
    TerraformMountains(),
    TerraformIslands(),
    TerraformCoast(),
    TerraformRockyIslands(),
    TerraformPassages(),
    TerraformAir(),
  ];

  Terraformer(this.model, {int? seed}) : _random = Random(seed);

  void shape() {
    TerrainMap map = TerrainMap(width: model.width, height: model.height, random: _random);

    for (TerraformPlugin plugin in plugins) {
      plugin.phase00Generate(map);
    }
    for (TerraformPlugin plugin in plugins) {
      plugin.phase01Smooth(map);
    }
    for (TerraformPlugin plugin in plugins) {
      plugin.phase02Connect(map);
    }
    for (TerraformPlugin plugin in plugins) {
      plugin.phase03Areas(map);
    }

    _putGroundIntoModel(map);

    for (TerraformPlugin plugin in plugins) {
      plugin.phase04Populate(model, map);
    }
  }

  void _putGroundIntoModel(TerrainMap map) {
    for (int x = 0; x < map.width; x++) {
      for (int y = 0; y < map.height; y++) {
        Cell cell = Cell(x, y);
        Type? ground = map.groundAt(cell);
        if (ground == null) {
          throw StateError('$cell has no ground: the plugins of phase00Generate must fill the map');
        }
        model.add(_agentFor(ground, cell));
        Type? heightArea = map.heightAreaAt(cell);
        if (heightArea != null) {
          model.add(_agentFor(heightArea, cell));
        }
      }
    }
  }

  AgentModel _agentFor(Type type, Cell cell) {
    if (type == WaterModel) return WaterModel(gameModelRef: model, cell: cell);
    if (type == FlatWaterModel) return FlatWaterModel(gameModelRef: model, cell: cell);
    if (type == BeachModel) return BeachModel(gameModelRef: model, cell: cell);
    if (type == SoilModel) return SoilModel(gameModelRef: model, cell: cell);
    if (type == HeightAreaLowModel) return HeightAreaLowModel(gameModelRef: model, cell: cell);
    if (type == HeightAreaMediumModel) return HeightAreaMediumModel(gameModelRef: model, cell: cell);
    if (type == HeightAreaHighModel) return HeightAreaHighModel(gameModelRef: model, cell: cell);
    throw ArgumentError('the terraformer does not know $type');
  }
}
