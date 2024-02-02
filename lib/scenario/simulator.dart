import 'dart:math';
import 'dart:ui' as ui;

import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/intvector2.dart';
import 'package:echo_garden/model/scheduler/base.dart';
import 'package:echo_garden/model/scheduler/random.dart';
import 'package:echo_garden/model/simulator.dart';
import 'package:echo_garden/scenario/flower.dart';
import 'package:echo_garden/scenario/grass.dart';
import 'package:echo_garden/scenario/patch.dart';
import 'package:echo_garden/scenario/rabbit.dart';
import 'package:echo_garden/scenario/tree.dart';
import 'package:echo_garden/scenario/water.dart';
import 'package:echo_garden/scenario/weed.dart';
import 'package:echo_garden/terraformer/diamond_square.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class EchoGardenSimulator extends Simulator {
  final ui.Paint backgroundPaint = ui.Paint()
    ..color = Colors.green[200]!; // Custom background color

  final numAgents = 200;

  late final BaseScheduler _rabbitScheduler;
  late final BaseScheduler _patchScheduler;

  double _accumulator = 0.0;
  final double _updateInterval = 1.1; // 100ms in seconds

  EchoGardenSimulator({required super.width, required super.height}) {
    _rabbitScheduler = RandomScheduler(model: this);
    _patchScheduler = RandomScheduler(model: this);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    var heightMap = diamondSquare(width, height);

    // Flatten the 2D heightMap into a sorted 1D list
    List<double> sortedHeights = heightMap.expand((row) => row).toList();
    sortedHeights.sort();

    // Find the water threshold for the lowest 20%
    int twentyPercentIndex = (sortedHeights.length * 0.2).floor();
    double waterThreshold = sortedHeights[twentyPercentIndex];
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        if (heightMap[x][y] < waterThreshold) {
          WaterPatch(scheduler: _patchScheduler, x: x, y: y);
        }
      }
    }

    var random = Random();
    for (int i = 0; i < numAgents; i++) {
      int x = random.nextInt(width);
      int y = random.nextInt(height);
      Patch? landmark = getAgentAtPosition<WaterPatch>(IntVector2(x, y));
      // do not place rabbits on the water....
      if (landmark == null) {
        RabbitAgent(scheduler: _rabbitScheduler, x: x, y: y);
      }
    }
  }

  @override
  void render(ui.Canvas canvas) {
    // Draw the background
    canvas.drawRect(size.toRect(), backgroundPaint);

    // Then draw the rest of the game on top of the background
    super.render(canvas);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _accumulator += dt;
    if (_accumulator >= _updateInterval) {
      // Time to update the game state
      step();
      // Reset the accumulator, subtracting _updateInterval to keep the remainder
      // This ensures consistent update intervals even if dt varies slightly
      _accumulator -= _updateInterval;
    }
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);

    Vector2 newCellSize = Vector2(gameSize.x / width, gameSize.y / height);

    agentsByCell.forEach((cell, agentsAtCell) {
      // Resize each agent in the set
      agentsAtCell.forEach((agent) {
        agent.resize(gameSize, newCellSize);
      });
    });
  }

  @override
  void step() {
    _grow();
    _patchScheduler.step();
    _rabbitScheduler.step();
  }

  void _grow() {
    var stopwatch = Stopwatch()..start();

    // Define the total number of agents to place for each type
    int totalGrass = (width * height * 0.05).toInt(); // Example: 5% of the grid
    int totalWeed = (width * height * 0.02).toInt(); // Example: 2% of the grid
    int totalFlower = (width * height * 0.005).toInt(); // Example: 1% of the grid
    int totalTree = (width * height * 0.001).toInt(); // Example: 0.1% of the grid

    void tryPlaceAgent(int total, Function(IntVector2) placeFunction, {int radius = 1}) {
      final random = Random();
      for (int i = 0; i < total; i++) {
        bool placed = false;

        // Randomly select a starting cell
        int x = random.nextInt(width);
        int y = random.nextInt(height);
        IntVector2 position = IntVector2(x, y);

        // Expand the search within the specified radius around the chosen cell
        for (int dx = -radius; dx <= radius && !placed; dx++) {
          for (int dy = -radius; dy <= radius && !placed; dy++) {
            int newX = (position.x + dx + width) % width; // Ensure wrapping around the grid
            int newY = (position.y + dy + height) % height;
            IntVector2 newCell = IntVector2(newX, newY);

            // If a position is empty, place the agent and mark as placed
            if (getAgentAtPosition<Agent>(newCell) == null) {
              placeFunction(newCell);
              placed = true;
            }
          }
        }
        // If the agent couldn't be placed after checking the radius, it's simply skipped
      }
    }

    // Attempt to place each type of agent
    tryPlaceAgent(totalGrass, (cell) => GrassPatch(scheduler: _patchScheduler, cell: cell));
    tryPlaceAgent(totalWeed, (cell) => WeedPatch(scheduler: _patchScheduler, cell: cell));
    tryPlaceAgent(totalFlower, (cell) => FlowerPatch(scheduler: _patchScheduler, cell: cell));
    tryPlaceAgent(totalTree, (cell) => TreePatch(scheduler: _patchScheduler, cell: cell));

    // Stop the stopwatch
    stopwatch.stop();

    // Print the elapsed time
    print('Grow function took ${stopwatch.elapsedMilliseconds} milliseconds');
  }

  void _grow2() {
    var stopwatch = Stopwatch()..start();

    final random = Random();
    // Define the total number of agents to place for each type
    int totalGrass = (width * height * 0.05).toInt(); // Example: 5% of the grid
    int totalWeed = (width * height * 0.02).toInt(); // Example: 2% of the grid
    int totalFlower = (width * height * 0.005).toInt(); // Example: 1% of the grid
    int totalTree = (width * height * 0.001).toInt(); // Example: 0.1% of the grid

    // A helper function to try placing an agent
    void tryPlaceAgent(int total, Function(IntVector2) placeFunction) {
      for (int i = 0; i < total; i++) {
        int x = random.nextInt(width);
        int y = random.nextInt(height);
        IntVector2 position = IntVector2(x, y);

        // Check if the position is empty
        if (getAgentAtPosition<Agent>(position) == null) {
          placeFunction(position);
        }
        // Note: If the position is not empty, this attempt is simply skipped.
        // You could implement a retry mechanism with a limit to improve placement success.
      }
    }

    // Attempt to place each type of agent
    tryPlaceAgent(totalGrass, (cell) => GrassPatch(scheduler: _patchScheduler, cell: cell));
    tryPlaceAgent(totalWeed, (cell) => WeedPatch(scheduler: _patchScheduler, cell: cell));
    tryPlaceAgent(totalFlower, (cell) => FlowerPatch(scheduler: _patchScheduler, cell: cell));
    tryPlaceAgent(totalTree, (cell) => TreePatch(scheduler: _patchScheduler, cell: cell));

    // Stop the stopwatch
    stopwatch.stop();

    // Print the elapsed time
    print('Grow function took ${stopwatch.elapsedMilliseconds} milliseconds');
  }

  void _grow1() {
    // Create and start the stopwatch
    var stopwatch = Stopwatch()..start();

    var random = Random();
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        bool empty = getAgentAtPosition<Agent>(IntVector2(x, y)) == null;
        if (empty) {
          int g = random.nextInt(30);
          // Simplified decision logic
          if (g <= 12) {
            GrassPatch(scheduler: _patchScheduler, x: x, y: y);
          } else if (g <= 14) {
            WeedPatch(scheduler: _patchScheduler, x: x, y: y);
          } else if (g == 15) {
            FlowerPatch(scheduler: _patchScheduler, x: x, y: y);
          }
        }
      }
    }

    // Stop the stopwatch
    stopwatch.stop();

    // Print the elapsed time
    print('Grow function took ${stopwatch.elapsedMilliseconds} milliseconds');
    // For more precise measurement, you can use elapsedMicroseconds
    //print('Grow function took ${stopwatch.elapsedMicroseconds} microseconds');
  }
}
