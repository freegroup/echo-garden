import 'dart:math';

import 'package:echo_garden/configuration.dart';

import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/objects/patch.dart';
import 'package:echo_garden/model/objects/plant.dart';
import 'package:echo_garden/model/objects/seedable.dart';
import 'package:echo_garden/utils/random.dart';
import 'package:echo_garden/model/strategy/base.dart';
import 'package:flame/components.dart';

class TreeModel extends PlantModel {
  late final MovementStrategy strategy;

  TreeModel({required super.scheduler, super.x, super.y, super.cell}) {
    strategy = MovementStrategy(model: scheduler.gameModelRef);
    energy = kGameConfiguration.plant.tree.initialEnergy;
  }

  @override
  void step() {
    _grow();
    _seed();
  }

  _grow() {
    energy = min(
      kGameConfiguration.plant.tree.maxEnergy,
      energy + kGameConfiguration.plant.tree.growEnergy,
    );
  }

  _seed() {
    var percentage = Random().nextInt(100).toDouble() / 100;
    if (percentage > kGameConfiguration.plant.tree.seedPercentage) {
      return;
    }

    if (energy >= kGameConfiguration.plant.tree.seedEnergy) {
      var cells = strategy.getNeighborhood(cell: cell, layerId: PlantModel.staticLayerId);
      Vector2? cellCandidate = pickRandomElement(cells);
      if (cellCandidate != null) {
        AgentModel? patch = gameModelRef.getAgentAtCell(cellCandidate, PatchModel.staticLayerId);
        AgentModel? plant = gameModelRef.getAgentAtCell(cellCandidate, PlantModel.staticLayerId);
        if (patch is SeedableModel && plant is! TreeModel) {
          TreeModel(scheduler: scheduler, cell: cellCandidate);
          plant?.die();
        }
      }
    }
  }
}
