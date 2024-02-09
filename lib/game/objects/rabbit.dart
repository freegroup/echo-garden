import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/objects/tile.dart';
import 'package:echo_garden/model/actors/rabbit.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

class RabbitTile extends TileSquare {
  MoveEffect? moveEffect;

  RabbitTile({required super.agentModel, required Vector2 position})
      : super(position: position, spriteFilenames: ["rabbit-01.png"]);

  @override
  void onModelChange() {
    print("rabbit changed....");
    final model = agentModel as RabbitAgent;
    final targetPosition = model.cell * kGameConfiguration.world.tileSize;

    moveEffect?.removeFromParent();
    // Create and apply the MoveEffect
    moveEffect = MoveEffect.to(
      targetPosition,
      EffectController(duration: 1.5, curve: Curves.easeInOut), // Use any easing curve you prefer
    );

    add(moveEffect!);
  }
}
