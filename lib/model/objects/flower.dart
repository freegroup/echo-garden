import 'dart:math';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/objects/flower.dart';
import 'package:echo_garden/model/objects/plant.dart';

class FlowerModel extends PlantModel {
  FlowerModel({required super.gameModelRef, required super.cell, super.energy}) {
    energy = kGameConfiguration.plant.flower.initialEnergy;
  }

  @override
  AgentVisualization createVisualization() {
    assert(visualization == null);
    return visualization = FlowerTile(
      agentModel: this,
      position: cell * kGameConfiguration.world.tileSize,
    );
  }

  @override
  Future<void> step() async  {
    var oldEnergy = energy;
    _grow();

    if (oldEnergy != energy) {
      visualization?.onModelChange();
    }
  }

  _grow() {
    energy = min(
      kGameConfiguration.plant.flower.maxEnergy,
      energy + kGameConfiguration.plant.flower.incEnergie,
    );
  }
}
