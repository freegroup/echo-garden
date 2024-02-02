import 'dart:math';

import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/intvector2.dart';
import 'package:echo_garden/model/random.dart';
import 'package:echo_garden/model/strategy/base.dart';
import 'package:echo_garden/scenario/configuration.dart';
import 'package:echo_garden/scenario/patch.dart';
import 'package:echo_garden/scenario/water.dart';
import 'package:flutter/material.dart';

class RabbitAgent extends Agent {
  double energy = 1;
  double birthThreshold = kConfiguration.rabbit.birthThreshold;

  late final MovementStrategy strategy;

  RabbitAgent({required super.scheduler, super.x, super.y, super.cell}) {
    strategy = MovementStrategy(model: scheduler.model);
    energy = Random().nextInt(kConfiguration.rabbit.initEnergy).toDouble();
    paint.color = Colors.brown;
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
    Set<IntVector2> possibleMoves = strategy.getNeighborhoodWithoutType<WaterPatch>(cell: cell);
    IntVector2? newCell = pickRandomElement(possibleMoves);
    if (newCell != null) {
      model.move(this, newCell);
    }
  }

  void _eat() {
    Patch? patch = model.getAgentAtPosition<Patch>(cell);
    if (patch != null && patch.energy < kConfiguration.rabbit.maxEnergyCanEat) {
      energy = energy + patch.energy;
      patch.die();
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
