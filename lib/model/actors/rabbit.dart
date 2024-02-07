import 'dart:math';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/actors/actor.dart';
import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/objects/plant.dart';
import 'package:echo_garden/model/strategy/base.dart';
import 'package:echo_garden/utils/random.dart';
import 'package:flame/components.dart';

class RabbitAgent extends ActorModel {
  double energy = 1;
  double birthThreshold = kConfiguration.rabbit.birthThreshold;

  late final MovementStrategy strategy;

  RabbitAgent({required super.scheduler, super.x, super.y, super.cell}) {
    strategy = MovementStrategy(model: scheduler.gameRef);
    energy = Random().nextInt(kConfiguration.rabbit.initEnergy).toDouble();
  }

  @override
  void step() {
    _move();
    _eat();
    _reproduce();
    energy = energy + kConfiguration.rabbit.energyPerStep;
    if (energy < 0) {
      die();
    }
  }

  void _move() {
    Set<Vector2> possibleMoves = strategy.getNeighborhood(
      includeCenter: false,
      cell: cell,
      layerTypeId: ActorModel.staticTypeId,
    );
    Vector2? newCell = pickRandomElement(possibleMoves);
    if (newCell != null) {
      gameRef.move(this, newCell);
    }
  }

  void _eat() {
    AgentModel? patch = gameRef.getAgentAtCell(cell, PlantModel.staticTypeId);
    if (patch != null && patch is PlantModel) {
      if (patch.energy < kConfiguration.rabbit.maxEnergyCanEat) {
        energy = energy + patch.energy;
        patch.die();
      }
    }
  }

  void _reproduce() {
    if (energy > birthThreshold) {
      energy = energy / 2;
      RabbitAgent child = RabbitAgent(scheduler: scheduler);
      child.cell = cell;
      child.energy = energy;
    }
  }
}
