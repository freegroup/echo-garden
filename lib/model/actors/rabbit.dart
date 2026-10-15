import 'dart:math';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/strategy/base.dart';
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
  void step() {
    bool changed = false;
    changed |= _move();
    changed |= _eat();
    changed |= _reproduce();
    energy = energy + kGameConfiguration.rabbit.energyPerStep;
    // the energy setter never goes below zero, so zero means starved
    if (energy <= 0) {
      gameModelRef.remove(this);
    } else if (changed) {
      gameModelRef.notifyChanged(this);
    }
  }

  // Land cells in step range that no other actor occupies. The actor layer
  // holds one agent per cell, so stepping onto a taken cell would overwrite it.
  Set<Vector2> _freeCells({required bool includeCenter}) {
    return strategy.getNeighborhood(
      includeCenter: includeCenter,
      emptyCellsLookup: false,
      cell: cell,
      radius: kGameConfiguration.rabbit.stepRadius,
      layerId: SeedableModel.staticLayerId,
    )..removeWhere((candidate) =>
        candidate != cell &&
        gameModelRef.getAgentAtCell(candidate, ActorModel.staticLayerId) != null);
  }

  bool _move() {
    Set<Vector2> possibleMoves = _freeCells(includeCenter: true);
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
          gameModelRef.notifyChanged(patch);
        }
        return true;
      }
    }
    return false;
  }

  bool _reproduce() {
    if (energy > birthThreshold) {
      // the young one needs a cell of its own next to the parent
      Vector2? birthCell = pickRandomElement(_freeCells(includeCenter: false));
      if (birthCell == null) {
        return false;
      }
      energy /= 2;
      gameModelRef.add(RabbitAgent(gameModelRef: gameModelRef, cell: birthCell, energy: energy));
      return true;
    }
    return false;
  }
}
