import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/objects/beach.dart';
import 'package:echo_garden/model/objects/flat_water.dart';
import 'package:flutter_test/flutter_test.dart';

GameModel newModel() =>
    GameModel(width: kGameConfiguration.grid.mapWidth, height: kGameConfiguration.grid.mapHeight);

List<HeightAreaModel> heightAreas(GameModel model) {
  List<HeightAreaModel> areas = [];
  for (MapEntry<Cell, AgentModel> entry
      in model.getLayer(HeightAreaModel.staticLayerId).getNonEmptyCellsAndAgents()) {
    areas.add(entry.value as HeightAreaModel);
  }
  return areas;
}

bool isWater(GameModel model, Cell cell) {
  AgentModel? patch = model.getAgentAtCell(cell, PatchModel.staticLayerId);
  return patch is WaterModel || patch is FlatWaterModel;
}

bool isLand(GameModel model, Cell cell) {
  return model.getAgentAtCell(cell, SeedableModel.staticLayerId) != null;
}

void main() {
  test('there are mountains of all three heights', () {
    final areas = heightAreas(newModel());

    expect(areas.whereType<HeightAreaLowModel>(), isNotEmpty);
    expect(areas.whereType<HeightAreaMediumModel>(), isNotEmpty);
    expect(areas.whereType<HeightAreaHighModel>(), isNotEmpty);
  });

  test('mountains stand on land or in the water, never on the beach', () {
    final model = newModel();

    for (HeightAreaModel area in heightAreas(model)) {
      bool onLand = isLand(model, area.cell);
      bool inWater = isWater(model, area.cell);
      expect(onLand || inWater, isTrue, reason: '${area.cell}');
      expect(model.getAgentAtCell(area.cell, PatchModel.staticLayerId), isNot(isA<BeachModel>()));
    }
  });

  test('mountains on land take about the configured share of the map', () {
    final model = newModel();
    var mountain = kGameConfiguration.mountain;
    double expectedPercentage =
        mountain.highPercentage + mountain.mediumPercentage + mountain.lowPercentage;

    int onLand = heightAreas(model).where((area) => isLand(model, area.cell)).length;
    double percentage = onLand * 100 / (model.width * model.height);

    expect(percentage, closeTo(expectedPercentage, 1.0));
  });

  test('rocky islands rise out of the water with their peak in the middle', () {
    final model = newModel();
    final islandPeaks = heightAreas(model)
        .whereType<HeightAreaHighModel>()
        .where((area) => isWater(model, area.cell))
        .toList();

    expect(islandPeaks, isNotEmpty);

    // every neighbor of an island peak is part of the peak or medium, never low
    for (HeightAreaHighModel peak in islandPeaks) {
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          Cell neighbor = Cell(peak.cell.x + dx, peak.cell.y + dy);
          AgentModel? area = model.getAgentAtCell(neighbor, HeightAreaModel.staticLayerId);
          expect(area is HeightAreaHighModel || area is HeightAreaMediumModel, isTrue,
              reason: 'neighbor $neighbor of the peak ${peak.cell}');
        }
      }
    }
  });

  test('grown mountain trees never stand right next to each other', () {
    final model = GameModel(
        width: kGameConfiguration.grid.mapWidth,
        height: kGameConfiguration.grid.mapHeight,
        seed: 3);
    for (var i = 0; i < 200; i++) {
      model.step();
    }

    bool isGrownMountainTree(AgentModel? a) =>
        (a is FirModel || a is PineModel) && (a as TreeModel).energy >= 40;

    int grownMountainTrees = 0;
    int adjacentPairs = 0;
    for (final entry in model.getLayer(PlantModel.staticLayerId).getNonEmptyCellsAndAgents()) {
      if (!isGrownMountainTree(entry.value)) continue;
      grownMountainTrees++;
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          if (dx == 0 && dy == 0) continue;
          final neighbor = model.getAgentAtCell(
              Cell(entry.key.x + dx, entry.key.y + dy), PlantModel.staticLayerId);
          if (isGrownMountainTree(neighbor)) adjacentPairs++;
        }
      }
    }

    expect(grownMountainTrees, greaterThan(0), reason: 'there should be mountain trees at all');
    expect(adjacentPairs, 0, reason: 'mountain trees must stay sparse');
  });

  test('plants only grow on ground they get along with', () {
    final model = newModel();
    for (var i = 0; i < 30; i++) {
      model.step();
    }

    Map<Type, List<Type>> growsOn = {
      GrassModel: kGameConfiguration.plant.grass.growsOn,
      WeedModel: kGameConfiguration.plant.weed.growsOn,
      FlowerModel: kGameConfiguration.plant.flower.growsOn,
      TreeModel: kGameConfiguration.plant.tree.growsOn,
      FirModel: kGameConfiguration.plant.fir.growsOn,
      PineModel: kGameConfiguration.plant.pine.growsOn,
    };
    int checked = 0;
    for (MapEntry<Cell, AgentModel> entry
        in model.getLayer(PlantModel.staticLayerId).getNonEmptyCellsAndAgents()) {
      List<Type>? allowed = growsOn[entry.value.runtimeType];
      // parched grass is what is left of grass, it does not grow by itself
      if (allowed == null) continue;
      expect(allowed, contains(model.groundTypeAt(entry.key)),
          reason: '${entry.value.runtimeType} on ${entry.key}');
      checked++;
    }
    expect(checked, greaterThan(0));
  });
}
