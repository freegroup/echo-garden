import 'dart:ui';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/objects/tile.dart';
import 'package:echo_garden/model/index.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

class GrassTile extends TileSquare {
  OpacityEffect? opacityEffect;
  GrassTile({required super.agentModel, required Vector2 position})
      : super(position: position, spriteFilenames: ["grass-01.png", "grass-02.png"]);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    spriteComponent?.setOpacity(0.0);
  }

  @override
  Future<void> onModelChange() async {
    var model = agentModel as GrassModel;

    var minEnergy = kGameConfiguration.plant.grass.initialEnergy;
    var maxEnergy = kGameConfiguration.plant.grass.maxEnergy;
    var currentEnergy = model.energy;

    // First, normalize currentEnergy to a value between 0 and 1
    double normalizedEnergy = (currentEnergy - minEnergy) / (maxEnergy - minEnergy);
    normalizedEnergy = clampDouble(normalizedEnergy, 0, 1);

    opacityEffect?.removeFromParent();
    opacityEffect = OpacityEffect.to(
      normalizedEnergy,
      EffectController(duration: 0.8, curve: Curves.easeInOut), // Adjust duration as needed
    );
    opacityEffect!.removeOnFinish = true;
    // Apply the effect to the SpriteComponent
    await spriteComponent?.add(opacityEffect!);
  }
}
