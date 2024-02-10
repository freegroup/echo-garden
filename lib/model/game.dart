import 'dart:math';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/game.dart';
import 'package:echo_garden/model/actors/rabbit.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/objects/beach.dart';
import 'package:echo_garden/model/objects/flat_water.dart';
import 'package:echo_garden/model/scheduler/base.dart';
import 'package:echo_garden/model/scheduler/random_percent.dart';
import 'package:echo_garden/model/strategy/base.dart';
import 'package:echo_garden/model/terraformer/diamond_square.dart';
import 'package:flame/game.dart';

class GameModel {
  late final Vector2 _size;
  late final BaseScheduler _rabbitScheduler;
  late final BaseScheduler _defaultScheduler;
  GameVisualization? gameVisualization;

  late Map<String, Layer> layersMap;

  int get width => _size.x.toInt();
  int get height => _size.y.toInt();

  GameModel(Vector2 size) {
    _size = size;
    layersMap = {
      PatchModel.staticLayerId: Layer(_size),
      SeedableModel.staticLayerId: Layer(_size),
      PlantModel.staticLayerId: Layer(_size),
      ActorModel.staticLayerId: Layer(_size),
    };

    _rabbitScheduler = RandomPercentScheduler(percent: 33, gameModelRef: this);
    _defaultScheduler = RandomPercentScheduler(percent: 53, gameModelRef: this);
    //_defaultScheduler = BaseScheduler(gameModelRef: this);

    var heightMap = diamondSquare(_size);

    // Flatten the 2D heightMap into a sorted 1D list
    List<double> sortedHeights = heightMap.expand((row) => row).toList();
    sortedHeights.sort();

    // Find the water threshold for the lowest 20%
    int twentyPercentIndex =
        (sortedHeights.length * (kGameConfiguration.world.waterPercentage / 100.0)).floor();
    double waterThreshold = sortedHeights[twentyPercentIndex];
    for (double x = 0; x < width; x++) {
      for (double y = 0; y < height; y++) {
        if (heightMap[x.toInt()][y.toInt()] < waterThreshold) {
          add(WaterModel(gameModelRef: this, cell: Vector2(x, y)));
        } else {
          add(SoilModel(gameModelRef: this, cell: Vector2(x, y)));
        }
      }
    }

    // place beach tiles near to the water.
    // this means convert "seedable" to "beach"
    //
    var placeChecker = MovementStrategy(model: this);
    for (double x = 0; x < width; x++) {
      for (double y = 0; y < height; y++) {
        Vector2 cell = Vector2(x, y);
        AgentModel? seedable = getAgentAtCell(cell, SeedableModel.staticLayerId);
        // check of around of the seedable is water => convert to beach
        if (seedable != null) {
          if (placeChecker.isAgentTypeNeighborOnLayer(
              cell: cell, layerId: PatchModel.staticLayerId, type: WaterModel)) {
            remove(seedable);
            add(BeachModel(gameModelRef: this, cell: cell));
          }
        }
      }
    }

    // place flat-water tiles near to the beach.
    // this means convert "seedable" to "beach"
    //
    for (double x = 0; x < width; x++) {
      for (double y = 0; y < height; y++) {
        Vector2 cell = Vector2(x, y);
        AgentModel? water = getAgentAtCell(cell, PatchModel.staticLayerId);
        // check of around of the seedable is water => convert to beach
        if (water is WaterModel) {
          if (placeChecker.isAgentTypeNeighborOnLayer(
              cell: cell, layerId: PatchModel.staticLayerId, type: BeachModel)) {
            remove(water);
            add(FlatWaterModel(gameModelRef: this, cell: cell));
          }
        }
      }
    }

    var numRabbits = 30;
    var random = Random();
    for (int i = 0; i < numRabbits; i++) {
      double x = random.nextInt(width).toDouble();
      double y = random.nextInt(height).toDouble();
      Vector2 cell = Vector2(x, y);
      AgentModel? landmark = getAgentAtCell(cell, SeedableModel.staticLayerId);
      // do not place rabbits on the water....
      if (landmark != null) {
        add(RabbitAgent(gameModelRef: this, cell: cell));
      }
    }
  }

  void add(AgentModel agent) async {
    layersMap[agent.layerId]?.add(agent.cell, agent);
    if (agent is RabbitAgent) {
      _rabbitScheduler.add(agent);
    } else {
      _defaultScheduler.add(agent);
    }
    await gameVisualization?.onModelAdded(agent);
  }

  void remove(AgentModel agent) async {
    if (agent is RabbitAgent) {
      _rabbitScheduler.remove(agent);
    } else {
      _defaultScheduler.remove(agent);
    }
    layersMap[agent.layerId]?.remove(agent);
    await gameVisualization?.onModelRemoved(agent);
  }

  void move(AgentModel agent, Vector2 newCell) async {
    layersMap[agent.layerId]?.move(agent, newCell);
    agent.cell = newCell;
    await gameVisualization?.onModelMoved(agent);
  }

  // Method to get a random agent of type T at a specific cell position
  AgentModel? getAgentAtCell(Vector2 cell, String layerId) {
    var layer = layersMap[layerId];
    if (layer == null) {
      print("No layer found......ERROR");
      return null;
    }
    return layer.get(cell);
  }

  // Method to get a random agent of type T at a specific cell position
  Layer getLayer(String layerId) {
    return layersMap[layerId]!;
  }

  void step() {
    _defaultScheduler.step();
    _rabbitScheduler.step();
    _grow();
  }

  void _grow() {
    var stopwatch = Stopwatch()..start();

    // Define the total number of agents to place for each type
    int area = width * height;
    int totalGrass = (area * kGameConfiguration.plant.grass.growPercentage).toInt();
    int totalWeed = (area * kGameConfiguration.plant.weed.growPercentage).toInt();
    int totalFlower = (area * kGameConfiguration.plant.flower.growPercentage).toInt();
    int totalTree = (area * kGameConfiguration.plant.tree.growPercentage).toInt();

    void placePlants(int total, Function(Vector2) placeFunction, {int radius = 1}) {
      final random = Random();
      for (int i = 0; i < total; i++) {
        bool placed = false;

        // Randomly select a starting cell
        int x = random.nextInt(_size.x.toInt());
        int y = random.nextInt(_size.y.toInt());

        // Expand the search within the specified radius around the chosen cell
        for (int dx = -radius; dx <= radius && !placed; dx++) {
          for (int dy = -radius; dy <= radius && !placed; dy++) {
            // Ensure wrapping around the grid
            double newX = ((x + dx + _size.x) % _size.x);
            double newY = ((y + dy + _size.y) % _size.y);
            Vector2 newCell = Vector2(newX, newY);

            // it is only possible to place "plants" on a seedable area
            //
            if (getAgentAtCell(newCell, SeedableModel.staticLayerId) != null) {
              // check that in this cell is not already a plant...first comes, first serves.
              //
              if (getAgentAtCell(newCell, PlantModel.staticLayerId) == null) {
                placeFunction(newCell);
                placed = true;
              }
            }
          }
        }
      }
    }

    placePlants(totalGrass, (cell) => add(GrassModel(gameModelRef: this, cell: cell)));
    placePlants(totalWeed, (cell) => add(WeedModel(gameModelRef: this, cell: cell)));
    placePlants(totalFlower, (cell) => add(FlowerModel(gameModelRef: this, cell: cell)));
    placePlants(totalTree, (cell) => add(TreeModel(gameModelRef: this, cell: cell)));

    // Stop the stopwatch
    stopwatch.stop();

    // Print the elapsed time
    print('Grow function took ${stopwatch.elapsedMilliseconds} milliseconds');
  }
}
