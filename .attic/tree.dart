import 'dart:math';

import 'package:echo_garden/intvector2.dart';
import 'package:echo_garden/model/random.dart';
import 'package:echo_garden/model/strategy/base.dart';
import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/visual/objects/patch.dart';
import 'package:echo_garden/visual/objects/plant.dart';
import 'package:echo_garden/visual/objects/water.dart';

import 'package:flame/extensions.dart';

class TreePatch extends Plant {
  late final MovementStrategy strategy;

  TreePatch({required super.scheduler, super.x, super.y, super.cell}) {
    strategy = MovementStrategy(model: scheduler.model);

    paint.color = kConfiguration.plant.tree.color;
    energy = kConfiguration.plant.tree.initialEnergy;
  }
  @override
  void render(Canvas canvas) {
    if (energy > kConfiguration.rabbit.maxEnergyCanEat) {
      canvas.drawRect(size.toRect(), paint);
    } else {
      canvas.drawOval(size.toRect(), paint);
    }
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

    // Convert energy range from 0-maxEnergy to 0.0-1.0 for opacity
    double opacity = energy / kConfiguration.plant.tree.maxEnergy;
    paint.color = kConfiguration.plant.tree.color.withOpacity(opacity);
  }

  _seed() {
    var percentage = Random().nextInt(100).toDouble() / 100;
    if (percentage > kConfiguration.plant.tree.seedPercentage) {
      return;
    }
    if (energy >= kConfiguration.plant.tree.seedEnergy) {
      Set<IntVector2> possibleMoves = strategy.getNeighborhoodWithoutType<TreePatch>(cell: cell);
      IntVector2? newCell = pickRandomElement(possibleMoves);
      if (newCell != null) {
        Patch? currentPatch = model.getAgentAtPosition(newCell);
        if (currentPatch is! WaterPatch) {
          TreePatch(scheduler: scheduler, cell: newCell);
          if (currentPatch != null) {
            currentPatch.die();
          }
        }
      }
    }
  }
}
