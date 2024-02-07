import 'dart:math';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/actors/actor.dart';
import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/layer.dart';
import 'package:echo_garden/model/objects/flower.dart';
import 'package:echo_garden/model/objects/grass.dart';
import 'package:echo_garden/model/objects/patch.dart';
import 'package:echo_garden/model/objects/plant.dart';
import 'package:echo_garden/model/objects/soil.dart';
import 'package:echo_garden/model/objects/tree.dart';
import 'package:echo_garden/model/objects/water.dart';
import 'package:echo_garden/model/objects/weed.dart';
import 'package:echo_garden/model/scheduler/base.dart';
import 'package:echo_garden/model/terraformer/diamond_square.dart';
import 'package:flame/game.dart';

class GameModel {
  late final Vector2 _size;
  late final BaseScheduler _rabbitScheduler;
  late final BaseScheduler _patchScheduler;

  late Map<String, Layer> layersMap;

  int get width => _size.x.toInt();
  int get height => _size.y.toInt();

  GameModel(Vector2 size) {
    _size = size;
    layersMap = {
      PatchModel.staticTypeId: Layer(_size),
      PlantModel.staticTypeId: Layer(_size),
      ActorModel.staticTypeId: Layer(_size),
    };

    _rabbitScheduler = BaseScheduler(gameRef: this);
    _patchScheduler = BaseScheduler(gameRef: this);

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
          add(WaterModel(scheduler: _patchScheduler, cell: Vector2(x, y)));
        } else {
          add(SoilModel(scheduler: _patchScheduler, cell: Vector2(x, y)));
        }
      }
    }
/*
    var random = Random();
    for (int i = 0; i < numAgents; i++) {
      int x = random.nextInt(width);
      int y = random.nextInt(height);
      Patch? landmark = getAgentAtPosition<WaterPatch>(IntVector2(x, y)) as Patch?;
      // do not place rabbits on the water....
      if (landmark == null) {
        RabbitAgent(scheduler: _rabbitScheduler, x: x, y: y);
      }
    }
    */
  }

  void add(AgentModel agent) {
    var layer = layersMap[agent.typeId]!;
    layer.add(agent.cell, agent);
  }

  void remove(AgentModel agent) {
    for (var layer in layersMap.values) {
      layer.removeAgent(agent);
    }
    _rabbitScheduler.remove(agent);
    _patchScheduler.remove(agent);
  }

  void move(AgentModel agent, Vector2 newCell) {
    for (var layer in layersMap.values) {
      layer.move(agent, newCell);
    }
  }

  // Method to get a random agent of type T at a specific cell position
  AgentModel? getAgentAtCell(Vector2 cell, String typeId) {
    var layer = layersMap[typeId];
    if (layer == null) {
      return null;
    }
    return layer.get(cell);
  }

  // Method to get a random agent of type T at a specific cell position
  Layer getLayer(String typeId) {
    return layersMap[typeId]!;
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
    int totalGrass = (area * kConfiguration.plant.grass.growPercentage).toInt();
    int totalWeed = (area * kConfiguration.plant.weed.growPercentage).toInt();
    int totalFlower = (area * kConfiguration.plant.flower.growPercentage).toInt();
    int totalTree = (area * kConfiguration.plant.tree.growPercentage).toInt();

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
            double newX = ((x + dx + _size.x) % _size.x); // Ensure wrapping around the grid
            double newY = ((y + dy + _size.y) % _size.y);
            Vector2 newCell = Vector2(newX, newY);

            // If a position is empty, place the agent and mark as placed
            if (getAgentAtCell(newCell, PlantModel.staticTypeId) == null) {
              placeFunction(newCell);
              placed = true;
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
