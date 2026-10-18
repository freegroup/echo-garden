import 'dart:math';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/actors/rabbit.dart';
import 'package:echo_garden/model/clock.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/movement_mode.dart';
import 'package:echo_garden/model/scheduler/random_percent.dart';
import 'package:echo_garden/model/terraformer/terraformer.dart';
import 'package:json_annotation/json_annotation.dart';

part 'game.g.dart'; // This file is generated

@JsonSerializable(explicitToJson: true)
class GameModel {
  // size of the map in cells
  final int width;
  final int height;

  // the same seed gives the same landscape; without a seed it is random
  final int? seed;

  // the random numbers of the simulation, from the seed, so a run can be
  // repeated (e.g. the breezes of the air)
  @JsonKey(includeFromJson: false, includeToJson: false)
  late final Random random;

  // the simulation time in milliseconds
  @JsonKey(includeFromJson: false, includeToJson: false)
  int now = 0;

  // the clocks, in the order they run when several are due at once
  @JsonKey(includeFromJson: false, includeToJson: false)
  late final Map<ClockKind, Clock> _clocks;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final List<ModelListener> _listeners = [];

  @JsonKey(includeFromJson: false, includeToJson: false)
  late Map<String, Layer> layersMap;

  // used by tests
  int get rabbitCount => _clocks[ClockKind.animal]!.scheduler.agents.length;

  GameModel({required this.width, required this.height, this.seed}) {
    random = Random(seed);
    layersMap = {
      PatchModel.staticLayerId: Layer(width, height),
      SeedableModel.staticLayerId: Layer(width, height),
      HeightAreaModel.staticLayerId: Layer(width, height),
      PlantModel.staticLayerId: Layer(width, height),
      ActorModel.staticLayerId: Layer(width, height),
      AirModel.staticLayerId: Layer(width, height),
    };

    var clocks = kGameConfiguration.clocks;
    _clocks = {
      ClockKind.ecology: Clock(
        kind: ClockKind.ecology,
        intervalMs: clocks.ecology.intervalMs,
        scheduler: RandomPercentScheduler(percent: clocks.ecology.percent, gameModelRef: this),
        afterStep: _grow,
      ),
      ClockKind.animal: Clock(
        kind: ClockKind.animal,
        intervalMs: clocks.animal.intervalMs,
        scheduler: RandomPercentScheduler(percent: clocks.animal.percent, gameModelRef: this),
      ),
      ClockKind.air: Clock(
        kind: ClockKind.air,
        intervalMs: clocks.air.intervalMs,
        scheduler: RandomPercentScheduler(percent: clocks.air.percent, gameModelRef: this),
      ),
    };

    Terraformer(this, seed: seed).shape();

    var numRabbits = 30;
    for (int i = 0; i < numRabbits; i++) {
      Cell cell = Cell(random.nextInt(width), random.nextInt(height));
      // only where rabbits can hop, and not on top of another rabbit
      if (hopping.canEnterCell(this, cell) &&
          getAgentAtCell(cell, ActorModel.staticLayerId) == null) {
        add(RabbitAgent(gameModelRef: this, cell: cell));
      }
    }
  }

  void addListener(ModelListener listener) {
    _listeners.add(listener);
  }

  void removeListener(ModelListener listener) {
    _listeners.remove(listener);
  }

  void add(AgentModel agent) {
    layersMap[agent.layerId]?.add(agent.cell, agent);
    _clocks[agent.clock]!.scheduler.add(agent);
    for (ModelListener listener in _listeners) {
      listener.onAgentAdded(agent);
    }
  }

  void remove(AgentModel agent) {
    _clocks[agent.clock]!.scheduler.remove(agent);
    layersMap[agent.layerId]?.remove(agent);
    for (ModelListener listener in _listeners) {
      listener.onAgentRemoved(agent);
    }
  }

  void move(AgentModel agent, Cell newCell) {
    layersMap[agent.layerId]?.move(agent, newCell);
    agent.cell = newCell;
    for (ModelListener listener in _listeners) {
      listener.onAgentMoved(agent);
    }
  }

  // Agents call this after their state (e.g. energy) has changed.
  void notifyChanged(AgentModel agent) {
    for (ModelListener listener in _listeners) {
      listener.onAgentChanged(agent);
    }
  }

  // Method to get a random agent of type T at a specific cell position
  AgentModel? getAgentAtCell(Cell cell, String layerId) {
    var layer = layersMap[layerId];
    if (layer == null) {
      print("No layer found......ERROR");
      return null;
    }
    return layer.get(cell);
  }

  /// The type of the topmost ground of a cell: a mountain, else the soil,
  /// else water or beach. Null for cells outside of the map.
  Type? groundTypeAt(Cell cell) {
    for (String layerId in [
      HeightAreaModel.staticLayerId,
      SeedableModel.staticLayerId,
      PatchModel.staticLayerId,
    ]) {
      AgentModel? ground = getAgentAtCell(cell, layerId);
      if (ground != null) {
        return ground.runtimeType;
      }
    }
    return null;
  }

  // Method to get a random agent of type T at a specific cell position
  Layer getLayer(String layerId) {
    return layersMap[layerId]!;
  }

  /// Lets [ms] of simulation time pass: every clock takes the steps that are
  /// due, in a fixed order.
  void advance(int ms) {
    now += ms;
    for (Clock clock in _clocks.values) {
      clock.advance(ms);
    }
  }

  /// One step of every clock, right now (used by tests).
  void step() {
    for (Clock clock in _clocks.values) {
      clock.step();
    }
  }

  void _grow() {
    var stopwatch = Stopwatch()..start();

    // Define the total number of agents to place for each type
    int area = width * height;
    int totalGrass = (area * kGameConfiguration.plant.grass.growPercentage).toInt();
    int totalWeed = (area * kGameConfiguration.plant.weed.growPercentage).toInt();
    int totalFlower = (area * kGameConfiguration.plant.flower.growPercentage).toInt();
    int totalTree = (area * kGameConfiguration.plant.tree.growPercentage).toInt();
    int totalFir = (area * kGameConfiguration.plant.fir.growPercentage).toInt();
    int totalPine = (area * kGameConfiguration.plant.pine.growPercentage).toInt();

    void placePlants(
        {required Function(Cell) placeFunction,
        required int total,
        int radius = 1,
        required double minWaterEnergyLevel,
        required List<Type> growsOn}) {
      final random = Random();
      for (int i = 0; i < total; i++) {
        bool placed = false;

        // Randomly select a starting cell
        int x = random.nextInt(width);
        int y = random.nextInt(height);

        // Expand the search within the specified radius around the chosen cell
        for (int dx = -radius; dx <= radius && !placed; dx++) {
          for (int dy = -radius; dy <= radius && !placed; dy++) {
            // Ensure wrapping around the grid
            int newX = (x + dx + width) % width;
            int newY = (y + dy + height) % height;
            Cell newCell = Cell(newX, newY);

            // it is only possible to place "plants" on a seedable area
            //
            AgentModel? patch = getAgentAtCell(newCell, SeedableModel.staticLayerId);
            if (patch is SeedableModel) {
              // check that in this cell is not already a plant...first comes, first serves.
              // ..that the patch has enough water to seed, and that the plant
              // gets along with the ground (e.g. no grass on high mountains).
              if (patch.energy > minWaterEnergyLevel &&
                  getAgentAtCell(newCell, PlantModel.staticLayerId) == null &&
                  PlantModel.growsAt(this, newCell, growsOn)) {
                placeFunction(newCell);
                placed = true;
              }
            }
          }
        }
      }
    }

    placePlants(
      total: totalGrass,
      minWaterEnergyLevel: kGameConfiguration.plant.grass.requiresMinWaterLevel,
      growsOn: kGameConfiguration.plant.grass.growsOn,
      placeFunction: (cell) => add(GrassModel(gameModelRef: this, cell: cell)),
    );
    placePlants(
      total: totalWeed,
      minWaterEnergyLevel: kGameConfiguration.plant.weed.requiresMinWaterLevel,
      growsOn: kGameConfiguration.plant.weed.growsOn,
      placeFunction: (cell) => add(WeedModel(gameModelRef: this, cell: cell)),
    );
    placePlants(
      total: totalFlower,
      minWaterEnergyLevel: kGameConfiguration.plant.flower.requiresMinWaterLevel,
      growsOn: kGameConfiguration.plant.flower.growsOn,
      placeFunction: (cell) => add(FlowerModel(gameModelRef: this, cell: cell)),
    );
    placePlants(
      total: totalTree,
      minWaterEnergyLevel: kGameConfiguration.plant.tree.requiresMinWaterLevel,
      growsOn: kGameConfiguration.plant.tree.growsOn,
      placeFunction: (cell) => add(TreeModel(gameModelRef: this, cell: cell)),
    );
    placePlants(
      total: totalFir,
      minWaterEnergyLevel: kGameConfiguration.plant.fir.requiresMinWaterLevel,
      growsOn: kGameConfiguration.plant.fir.growsOn,
      placeFunction: (cell) => add(FirModel(gameModelRef: this, cell: cell)),
    );
    placePlants(
      total: totalPine,
      minWaterEnergyLevel: kGameConfiguration.plant.pine.requiresMinWaterLevel,
      growsOn: kGameConfiguration.plant.pine.growsOn,
      placeFunction: (cell) => add(PineModel(gameModelRef: this, cell: cell)),
    );

    // Stop the stopwatch
    stopwatch.stop();

    // Print the elapsed time
    print('Grow function took ${stopwatch.elapsedMilliseconds} milliseconds');
  }

  // Serialization
  factory GameModel.fromJson(Map<String, dynamic> json) => _$GameModelFromJson(json);
  Map<String, dynamic> toJson() => _$GameModelToJson(this);
}
