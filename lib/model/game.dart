import 'dart:math';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/game.dart';
import 'package:echo_garden/model/actors/rabbit.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/scheduler/base.dart';
import 'package:echo_garden/model/scheduler/random_percent.dart';
import 'package:echo_garden/model/terraformer/diamond_square.dart';
import 'package:flame/game.dart';

class GameModel {
  late final Vector2 _size;
  late final BaseScheduler _rabbitScheduler;
  late final BaseScheduler _patchScheduler;
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
    _patchScheduler = BaseScheduler(gameModelRef: this);

    var heightMap = diamondSquare(_size);

    // Flatten the 2D heightMap into a sorted 1D list
    List<double> sortedHeights = heightMap.expand((row) => row).toList();
    sortedHeights.sort();

    // Find the water threshold for the lowest 20%
    int twentyPercentIndex = (sortedHeights.length * 0.2).floor();
    double waterThreshold = sortedHeights[twentyPercentIndex];
    for (double x = 0; x < width; x++) {
      for (double y = 0; y < height; y++) {
        if (heightMap[x.toInt()][y.toInt()] < waterThreshold) {
          WaterModel(scheduler: _patchScheduler, cell: Vector2(x, y));
        } else {
          SoilModel(scheduler: _patchScheduler, cell: Vector2(x, y));
        }
      }
    }

    var numRabbits = 300;
    var random = Random();
    for (int i = 0; i < numRabbits; i++) {
      double x = random.nextInt(width).toDouble();
      double y = random.nextInt(height).toDouble();
      AgentModel? landmark = getAgentAtCell(Vector2(x, y), SeedableModel.staticLayerId);
      // do not place rabbits on the water....
      if (landmark != null) {
        print("add rabbit");
        RabbitAgent(scheduler: _rabbitScheduler, x: x, y: y);
      }
    }
  }

  Future<void> add(AgentModel agent) async {
    var layer = layersMap[agent.layerId]!;
    layer.add(agent.cell, agent);
    gameVisualization?.onModelAdded(agent);
  }

  void remove(AgentModel agent) {
    var layer = layersMap[agent.layerId]!;
    layer.removeAgent(agent);
    _rabbitScheduler.remove(agent);
    _patchScheduler.remove(agent);
    gameVisualization?.onModelRemoved(agent);
  }

  void move(AgentModel agent, Vector2 newCell) {
    var layer = layersMap[agent.layerId]!;
    layer.move(agent, newCell);
    agent.cell = newCell;
    gameVisualization?.onModelMoved(agent);
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
    _grow();
    _patchScheduler.step();
    _rabbitScheduler.step();
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

    placePlants(totalGrass, (cell) => GrassModel(scheduler: _patchScheduler, cell: cell));
    placePlants(totalWeed, (cell) => WeedModel(scheduler: _patchScheduler, cell: cell));
    placePlants(totalFlower, (cell) => FlowerModel(scheduler: _patchScheduler, cell: cell));
    placePlants(totalTree, (cell) => TreeModel(scheduler: _patchScheduler, cell: cell));

    // Stop the stopwatch
    stopwatch.stop();

    // Print the elapsed time
    print('Grow function took ${stopwatch.elapsedMilliseconds} milliseconds');
  }
}
