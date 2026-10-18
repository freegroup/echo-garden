import 'dart:math';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/objects/air.dart';
import 'package:echo_garden/model/cell.dart';
import 'package:echo_garden/model/objects/plant.dart';
import 'package:echo_garden/model/objects/seedable.dart';
import 'package:echo_garden/strategy/base.dart';
import 'package:echo_garden/utils/random.dart';

class TreeModel extends PlantModel {
  late final MovementStrategy strategy;

  TreeModel({required super.gameModelRef, required super.cell, super.energy}) {
    strategy = MovementStrategy(model: gameModelRef);
    energy = settings.initialEnergy;
  }

  // the values of this kind of tree in the configuration
  TreeSettings get settings => kGameConfiguration.plant.tree;

  // the young tree that grows from a seed of this tree
  TreeModel createSeedling(Cell cell) {
    return TreeModel(gameModelRef: gameModelRef, cell: cell);
  }

  @override
  void step() {
    bool changed = false;
    changed |= _grow();
    changed |= _seed();
    _cleanAir();

    if (changed) gameModelRef.notifyChanged(this);

    if (energy <= 0) {
      gameModelRef.remove(this);
    }
  }

  // The tree takes a little fine dust out of the air on its cell. The air
  // does not know about trees; the tree decides to read and change it.
  void _cleanAir() {
    AgentModel? air = gameModelRef.getAgentAtCell(cell, AirModel.staticLayerId);
    if (air is AirModel) {
      air.addDust(-settings.absorbsDust);
    }
  }

  bool _grow() {
    // Bigger trees nearby take the light and water: this tree does not grow
    // but loses energy and eventually dies. So mountains stay sparse, while
    // the oak (with no crowding limit) can still form a dense forest.
    if (_largerNeighborEnergy(cell, energy) > settings.maxCrowdingEnergy) {
      energy -= settings.crowdingPenalty;
      return true;
    }
    return super.grow(
      settings.growEnergy,
      settings.maxEnergy,
      settings.requiresMinWaterLevel,
    );
  }

  // Summed energy of neighboring trees that are bigger than [ownEnergy].
  double _largerNeighborEnergy(Cell center, double ownEnergy) {
    double sum = 0;
    Set<Cell> neighbors = strategy.getNeighborhood(
      cell: center,
      layerId: PlantModel.staticLayerId,
      radius: settings.crowdingRadius,
      emptyCellsLookup: false,
    );
    for (Cell neighbor in neighbors) {
      AgentModel? plant = gameModelRef.getAgentAtCell(neighbor, PlantModel.staticLayerId);
      if (plant is TreeModel && plant.energy > ownEnergy) {
        sum += plant.energy;
      }
    }
    return sum;
  }

  bool _seed() {
    var percentage = Random().nextInt(100).toDouble() / 100;
    if (percentage > settings.seedPercentage) {
      return false;
    }

    if (energy >= settings.seedEnergy) {
      var cells = strategy.getNeighborhood(
        cell: cell,
        layerId: PlantModel.staticLayerId,
        emptyCellsLookup: false,
      );
      Cell? cellCandidate = pickRandomElement(cells);
      if (cellCandidate != null) {
        AgentModel? patch = gameModelRef.getAgentAtCell(cellCandidate, SeedableModel.staticLayerId);
        AgentModel? plant = gameModelRef.getAgentAtCell(cellCandidate, PlantModel.staticLayerId);

        bool growsThere = PlantModel.growsAt(gameModelRef, cellCandidate, settings.growsOn);
        // a new seedling is tiny (energy 0), so every tree nearby counts: do
        // not seed into a spot that is already crowded
        bool crowded = _largerNeighborEnergy(cellCandidate, 0) > settings.maxCrowdingEnergy;
        // trees and firs do not push each other away
        if (patch is SeedableModel && plant is! TreeModel && growsThere && !crowded) {
          if (patch.energy > settings.requiresMinWaterLevel) {
            // replace "anything" with the new tree
            if (plant != null) gameModelRef.remove(plant);
            gameModelRef.add(createSeedling(cellCandidate));
            return true;
          }
        }
      }
    }
    return false;
  }
}

/// A fir grows like a tree, but also higher up in the mountains.
class FirModel extends TreeModel {
  FirModel({required super.gameModelRef, required super.cell, super.energy});

  @override
  TreeSettings get settings => kGameConfiguration.plant.fir;

  @override
  TreeModel createSeedling(Cell cell) {
    return FirModel(gameModelRef: gameModelRef, cell: cell);
  }
}

/// A pine grows like a tree, but only on the medium mountains.
class PineModel extends TreeModel {
  PineModel({required super.gameModelRef, required super.cell, super.energy});

  @override
  TreeSettings get settings => kGameConfiguration.plant.pine;

  @override
  TreeModel createSeedling(Cell cell) {
    return PineModel(gameModelRef: gameModelRef, cell: cell);
  }
}
