import 'dart:math';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/objects/tree.dart';

import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/objects/patch.dart';
import 'package:echo_garden/model/objects/plant.dart';
import 'package:echo_garden/model/objects/seedable.dart';
import 'package:echo_garden/utils/random.dart';
import 'package:echo_garden/model/strategy/base.dart';
import 'package:flame/components.dart';

class TreeModel extends PlantModel {
  late final MovementStrategy strategy;

  TreeModel({required super.gameModelRef, required super.cell, super.energy}) {
    strategy = MovementStrategy(model: gameModelRef);
    energy = kGameConfiguration.plant.tree.initialEnergy;
  }

  @override
  AgentVisualization createVisualization() {
    assert(visualization == null);
    return visualization = TreeTile(
      agentModel: this,
      position: cell * kGameConfiguration.world.tileSize,
    );
  }

  @override
  void step() {
    bool changed = false;
    changed |= _grow();
    changed |= _seed();

    if (changed) visualization?.onModelChange();
  }

  bool _grow() {
    if (energy >= kGameConfiguration.plant.tree.maxEnergy) {
      return false;
    }
    energy = min(
      kGameConfiguration.plant.tree.maxEnergy,
      energy + kGameConfiguration.plant.tree.growEnergy,
    );
    return true;
  }

  bool _seed() {
    var percentage = Random().nextInt(100).toDouble() / 100;
    if (percentage > kGameConfiguration.plant.tree.seedPercentage) {
      return false;
    }

    if (energy >= kGameConfiguration.plant.tree.seedEnergy) {
      var cells = strategy.getNeighborhood(
        cell: cell,
        layerId: PlantModel.staticLayerId,
        emptyCellsLookup: false,
      );
      Vector2? cellCandidate = pickRandomElement(cells);
      if (cellCandidate != null) {
        AgentModel? patch = gameModelRef.getAgentAtCell(cellCandidate, SeedableModel.staticLayerId);
        AgentModel? plant = gameModelRef.getAgentAtCell(cellCandidate, PlantModel.staticLayerId);

        if (patch is SeedableModel && plant is! TreeModel) {
          // replace "anything" with the new tree
          if (plant != null) gameModelRef.remove(plant);
          gameModelRef.add(TreeModel(gameModelRef: gameModelRef, cell: cellCandidate));
          return true;
        }
      }
    }
    return false;
  }
}
