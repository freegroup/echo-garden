import 'dart:math';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/objects/rabbit.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/strategy/base.dart';
import 'package:echo_garden/utils/random.dart';
import 'package:flame/components.dart';

class RabbitAgent extends ActorModel {
  double birthThreshold = kGameConfiguration.rabbit.birthThreshold;

  late final MovementStrategy strategy;

  RabbitAgent({required super.gameModelRef, required super.cell, super.energy}) {
    strategy = MovementStrategy(model: gameModelRef);
    energy =
        energy == 0 ? Random().nextInt(kGameConfiguration.rabbit.initEnergy).toDouble() : energy;
  }

  @override
  AgentVisualization createVisualization() {
    assert(visualization == null);
    return visualization =
        RabbitTile(agentModel: this, position: cell * kGameConfiguration.world.tileSize);
  }

  @override
  void step() {
    bool changed = false;
    changed |= _move();
    changed |= _eat();
    changed |= _reproduce();
    energy = energy + kGameConfiguration.rabbit.energyPerStep;
    if (energy < 0) {
      gameModelRef.remove(this);
    } else if (changed) {
      visualization?.onModelChange();
    }
    if (visualization != null) {
      assert(visualization!.parent != null);
    }
  }

  bool _move() {
    Set<Vector2> possibleMoves = strategy.getNeighborhood(
      includeCenter: true,
      emptyCellsLookup: false,
      cell: cell,
      layerId: SeedableModel.staticLayerId,
    );
    Vector2? newCell = pickRandomElement(possibleMoves);
    if (newCell != null) {
      gameModelRef.move(this, newCell);
      return true;
    }
    return false;
  }

  bool _eat() {
    AgentModel? patch = gameModelRef.getAgentAtCell(cell, PlantModel.staticLayerId);
    if (patch != null && patch is PlantModel) {
      if (patch.energy < kGameConfiguration.rabbit.maxEnergyCanEat) {
        var diff = min(patch.energy, kGameConfiguration.rabbit.maxEnergyPerEat);
        energy += diff;
        patch.energy -= diff;
        if (patch.energy <= 0) {
          gameModelRef.remove(patch);
        } else {
          patch.visualization?.onModelChange();
        }
        return true;
      }
    }
    return false;
  }

  bool _reproduce() {
    if (energy > birthThreshold) {
      energy /= 2;
      gameModelRef.add(RabbitAgent(gameModelRef: gameModelRef, cell: cell, energy: energy));
      return true;
    }
    return false;
  }
}
