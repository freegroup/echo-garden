import 'dart:math';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/movement_mode.dart';
import 'package:echo_garden/strategy/base.dart';
import 'package:echo_garden/utils/random.dart';

class RabbitAgent extends ActorModel {
  double birthThreshold = kGameConfiguration.rabbit.birthThreshold;

  late final MovementStrategy strategy;

  // decides where the rabbit can hop
  MovementMode movementMode = hopping;

  RabbitAgent({required super.gameModelRef, required super.cell, super.energy}) {
    strategy = MovementStrategy(model: gameModelRef);
    energy =
        energy == 0 ? Random().nextInt(kGameConfiguration.rabbit.initEnergy).toDouble() : energy;
  }

  @override
  void step() {
    _move();
    _eat();
    _reproduce();
    energy = energy + kGameConfiguration.rabbit.energyPerStep;
    // the energy setter never goes below zero, so zero means starved
    if (energy <= 0) {
      gameModelRef.remove(this);
    }
  }

  // Cells in step range the rabbit can hop to. The movement mode decides about
  // the ground; the rabbit itself only avoids other rabbits, because the actor
  // layer holds one agent per cell and stepping onto a taken cell would
  // overwrite it.
  Set<Cell> _freeCells({required bool includeCenter}) {
    Set<Cell> cells = strategy.getCellsAround(
      cell: cell,
      radius: kGameConfiguration.rabbit.stepRadius,
      includeCenter: includeCenter,
    );
    cells.removeWhere((candidate) => !movementMode.canEnterCell(gameModelRef, candidate));
    cells.removeWhere((candidate) =>
        candidate != cell &&
        gameModelRef.getAgentAtCell(candidate, ActorModel.staticLayerId) != null);
    return cells;
  }

  bool _move() {
    Set<Cell> possibleMoves = _freeCells(includeCenter: true);
    Cell? newCell = pickRandomElement(possibleMoves);
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
        }
        return true;
      }
    }
    return false;
  }

  bool _reproduce() {
    if (energy > birthThreshold) {
      // the young one needs a cell of its own next to the parent
      Cell? birthCell = pickRandomElement(_freeCells(includeCenter: false));
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
