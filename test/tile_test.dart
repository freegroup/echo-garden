import 'dart:typed_data';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/messages.dart';
import 'package:echo_garden/model/objects/beach.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_beach.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_fir.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_flower.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_grass.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_soil.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_tree.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_water.dart';
import 'package:echo_garden/representation/world_view.dart';
import 'package:flutter_test/flutter_test.dart';

int _nextId = 0;

AgentState state(Type type, String layerId, Cell cell, {double energy = 0}) {
  return AgentState(id: _nextId++, type: type, layerId: layerId, cell: cell, energy: energy);
}

// A world view of one row: water, beach, soil, soil with grass.
WorldView rowOfGround() {
  List<AgentState> agents = [
    state(WaterModel, PatchModel.staticLayerId, const Cell(0, 0)),
    state(BeachModel, PatchModel.staticLayerId, const Cell(1, 0)),
    state(SoilModel, SeedableModel.staticLayerId, const Cell(2, 0)),
    state(SoilModel, SeedableModel.staticLayerId, const Cell(3, 0)),
    state(GrassModel, PlantModel.staticLayerId, const Cell(3, 0)),
  ];
  return WorldView(WorldSnapshot(
    width: 4,
    height: 1,
    agents: agents,
    wind: WindState(directions: Uint8List(4), strengths: Float32List(4)),
  ));
}

AgentView plant(Type type, Cell cell, double energy) {
  return AgentView(state(type, PlantModel.staticLayerId, cell, energy: energy));
}

void main() {
  group('ground', () {
    test('a terrain covers its own cells and the cells of higher terrains', () {
      WorldView view = rowOfGround();
      // water lies under everything, soil only on soil
      expect([for (int x = 0; x < 4; x++) TileWater().covers(view, x, 0)], [true, true, true, true]);
      expect([for (int x = 0; x < 4; x++) TileBeach().covers(view, x, 0)], [false, true, true, true]);
      expect([for (int x = 0; x < 4; x++) TileSoil().covers(view, x, 0)], [false, false, true, true]);
    });

    test('beyond the edge of the map the cell at the edge counts', () {
      WorldView view = rowOfGround();
      expect(TileSoil().covers(view, -1, 0), isFalse, reason: 'left of the water');
      expect(TileSoil().covers(view, 4, 0), isTrue, reason: 'right of the soil');
    });

    test('grass covers only the cells where grass grows', () {
      WorldView view = rowOfGround();
      expect([for (int x = 0; x < 4; x++) TileGrass().covers(view, x, 0)], [false, false, false, true]);
    });
  });

  group('plants', () {
    test('a tree grows through its images, from its first energy to its full energy', () {
      var tree = kGameConfiguration.plant.tree;
      TileTree tile = TileTree();
      expect(tile.imageIndexFor(plant(TreeModel, const Cell(0, 0), tree.initialEnergy)), 0);
      expect(tile.imageIndexFor(plant(TreeModel, const Cell(0, 0), tree.maxEnergy)), 3);
      expect(tile.imageIndexFor(plant(TreeModel, const Cell(0, 0), tree.maxEnergy * 10)), 3);
    });

    test('a fir grows with the settings of the firs', () {
      var fir = kGameConfiguration.plant.fir;
      TileFir tile = TileFir();
      expect(tile.imageIndexFor(plant(FirModel, const Cell(0, 0), fir.initialEnergy)), 0);
      expect(tile.imageIndexFor(plant(FirModel, const Cell(0, 0), fir.maxEnergy)), 3);
    });

    test('a tree is mirrored or not by its cell, the same every time', () {
      TileTree tile = TileTree();
      List<bool> first = [for (int x = 0; x < 10; x++) tile.mirroredFor(plant(TreeModel, Cell(x, 3), 5))];
      List<bool> again = [for (int x = 0; x < 10; x++) tile.mirroredFor(plant(TreeModel, Cell(x, 3), 9))];
      expect(again, first, reason: 'it does not depend on the energy');
      expect(first, containsAll([true, false]), reason: 'some are mirrored, some not');
    });

    test('a flower keeps the variant of its cell', () {
      TileFlower tile = TileFlower();
      List<int> first = [for (int x = 0; x < 10; x++) tile.imageIndexFor(plant(FlowerModel, Cell(x, 1), 1))];
      List<int> again = [for (int x = 0; x < 10; x++) tile.imageIndexFor(plant(FlowerModel, Cell(x, 1), 1))];
      expect(again, first);
      expect(first.toSet(), {0, 1}, reason: 'both images are used');
    });

    test('a young flower is hardly to be seen, a grown one fully', () {
      var flower = kGameConfiguration.plant.flower;
      TileFlower tile = TileFlower();
      expect(tile.opacityFor(plant(FlowerModel, const Cell(0, 0), flower.initialEnergy)), 0);
      expect(tile.opacityFor(plant(FlowerModel, const Cell(0, 0), flower.maxEnergy)), 1);
    });
  });
}
