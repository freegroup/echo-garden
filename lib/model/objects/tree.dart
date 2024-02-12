import 'dart:math';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/objects/tree.dart';
import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/objects/plant.dart';
import 'package:echo_garden/model/objects/seedable.dart';
import 'package:echo_garden/strategy/base.dart';
import 'package:echo_garden/utils/random.dart';
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
  Future<void> step() async {
    bool changed = false;
    changed |= _grow();
    changed |= await _seed();

    if (changed) visualization?.onModelChange();

    if (energy <= 0) {
      gameModelRef.remove(this);
    }
  }

  bool _grow() {
    return super.grow(
      kGameConfiguration.plant.tree.growEnergy,
      kGameConfiguration.plant.tree.maxEnergy,
      kGameConfiguration.plant.tree.requiresMinWaterLevel,
    );
  }

  Future<bool> _seed() async {
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
          if (patch.energy > kGameConfiguration.plant.tree.requiresMinWaterLevel) {
            // replace "anything" with the new tree
            if (plant != null) gameModelRef.remove(plant);
            await gameModelRef.add(TreeModel(gameModelRef: gameModelRef, cell: cellCandidate));
            return true;
          }
        }
      }
    }
    return false;
  }
}
