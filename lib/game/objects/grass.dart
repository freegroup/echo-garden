import 'dart:math';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/objects/growing_tile.dart';
import 'package:echo_garden/model/index.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

class GrassTile extends GrowingTileSquare {
  OpacityEffect? opacityEffect;
  GrassTile({required super.agentModel, required Vector2 position})
      : super(
          position: position,
          canFlipHorizontal: true,
          canFlipVertical: true,
          spriteFilenames: [
            "grass-01.png",
            "grass-02.png",
            "grass-03.png",
            "grass-04.png",
            "grass-05.png",
            "grass-06.png",
            "grass-07.png",
          ],
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // spriteComponent?.setOpacity(0.0);
    await onModelChange();
  }

  @override
  Future<void> onModelChange() async {
    var model = agentModel as GrassModel;

    var minEnergy = kGameConfiguration.plant.grass.initialEnergy;
    var maxEnergy = kGameConfiguration.plant.grass.maxEnergy;
    var currentEnergy = model.energy;

    setTileToShow(currentEnergy, minEnergy, maxEnergy);

/*
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
*/
  }
}
