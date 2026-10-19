import 'dart:ui';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/objects/tile.dart';
import 'package:flame/components.dart';

class FlowerTile extends TileSquare {
  FlowerTile({required super.agent, required Vector2 position})
      : super(position: position, spriteFilenames: ["flower-01.png", "flower-02.png"]);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    spriteComponent?.setOpacity(0.0);
    await onModelChange();
  }

  @override
  Future<void> onModelChange() async {
    var minEnergy = kGameConfiguration.plant.flower.initialEnergy;
    var maxEnergy = kGameConfiguration.plant.flower.maxEnergy;
    var currentEnergy = agent.energy;

    // First, normalize currentEnergy to a value between 0 and 1
    double normalizedEnergy = (currentEnergy - minEnergy) / (maxEnergy - minEnergy);
    normalizedEnergy = clampDouble(normalizedEnergy, 0, 1);
    spriteComponent?.setOpacity(normalizedEnergy);
  }
}
