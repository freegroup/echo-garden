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
    strategy = MovementStrategy(model: scheduler.gameRef);
    energy = kConfiguration.plant.tree.initialEnergy;
  }

  @override
  void step() {
    _grow();
    _seed();
  }

  _grow() {
    energy = min(
      kConfiguration.plant.tree.maxEnergy,
      energy + kConfiguration.plant.tree.growEnergy,
    );
  }

  _seed() {
    var percentage = Random().nextInt(100).toDouble() / 100;
    if (percentage > kConfiguration.plant.tree.seedPercentage) {
      return;
    }

    if (energy >= kConfiguration.plant.tree.seedEnergy) {
      var cells = strategy.getNeighborhood(cell: cell, layerTypeId: PlantModel.staticTypeId);
      Vector2? cellCandidate = pickRandomElement(cells);
      if (cellCandidate != null) {
        AgentModel? patch = gameRef.getAgentAtCell(cellCandidate, PatchModel.staticTypeId);
        AgentModel? plant = gameRef.getAgentAtCell(cellCandidate, PlantModel.staticTypeId);
        if (patch is SeedableModel && plant is! TreeModel) {
          TreeModel(scheduler: scheduler, cell: cellCandidate);
          plant?.die();
        }
      }
    }
  }
}
