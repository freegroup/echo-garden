import 'dart:math';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';

class EmberPlayer extends SpriteAnimationComponent
    with HasGameReference<GameVisualization>, KeyboardHandler {
  late final Vector2 velocity;
  final double runSpeed = 250.0;
  EmberPlayer({
    required super.position,
  }) : super(size: Vector2.all(kGameConfiguration.world.tileSize), anchor: Anchor.center) {
    velocity = Vector2(0, 0);
  }

  @override
  void onLoad() {
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('ember.png'),
      SpriteAnimationData.sequenced(
        amount: 4,
        textureSize: Vector2.all(16),
        stepTime: 0.12,
      ),
    );
  }

  @override
  void update(double dt) {
    position += velocity * dt;
    /*
    if (position.y > game.gameModel.height * 64) {
      position.y = game.gameModel.height * 64;
    }
    if (position.y < 0) {
      position.y = 0;
    }

    if (position.x > game.gameModel.width * 64) {
      position.x = game.gameModel.width * 64;
    }
    if (position.x < 0) {
      position.x = 0;
    }
    */
    //print((position / worldTileSize)..floor());
    double alignment = 5;
    Vector2 cellPlayer = (position / kGameConfiguration.world.tileSize)..floor();
    // Calculate the aligned starting points
    double alignedStartX = max(0,
        (cellPlayer.x - kGameConfiguration.world.visibleTileRadius ~/ 2) ~/ alignment * alignment);
    double alignedStartY = max(0,
        (cellPlayer.y - kGameConfiguration.world.visibleTileRadius ~/ 2) ~/ alignment * alignment);

    Rect cellsAroundPlayer = Rect.fromLTWH(
      alignedStartX,
      alignedStartY,
      kGameConfiguration.world.visibleTileRadius,
      kGameConfiguration.world.visibleTileRadius,
    );
    // center the rect around the player
    game.world.cellsToShow = cellsAroundPlayer;
    super.update(dt);
  }

  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final isKeyDown = event is RawKeyDownEvent;
    final keyLeft = (event.logicalKey == LogicalKeyboardKey.arrowLeft) ||
        (event.logicalKey == LogicalKeyboardKey.keyA);
    final keyRight = (event.logicalKey == LogicalKeyboardKey.arrowRight) ||
        (event.logicalKey == LogicalKeyboardKey.keyD);
    final keyUp = (event.logicalKey == LogicalKeyboardKey.arrowUp) ||
        (event.logicalKey == LogicalKeyboardKey.keyW);
    final keyDown = (event.logicalKey == LogicalKeyboardKey.arrowDown) ||
        (event.logicalKey == LogicalKeyboardKey.keyX);

    if (isKeyDown) {
      if (keyLeft) {
        velocity.x = -runSpeed;
      } else if (keyRight) {
        velocity.x = runSpeed;
      } else if (keyUp) {
        velocity.y = -runSpeed;
      } else if (keyDown) {
        velocity.y = runSpeed;
      }
    } else {
      final hasLeft = keysPressed.contains(LogicalKeyboardKey.arrowLeft);
      final hasRight = keysPressed.contains(LogicalKeyboardKey.arrowRight);
      final hasUp = keysPressed.contains(LogicalKeyboardKey.arrowUp);
      final hasDown = keysPressed.contains(LogicalKeyboardKey.arrowDown);

      if (hasLeft && hasRight) {
        // Leave the current speed unchanged
      } else if (hasLeft) {
        velocity.x = -runSpeed;
      } else if (hasRight) {
        velocity.x = runSpeed;
      } else {
        velocity.x = 0;
      }

      if (hasUp && hasDown) {
        // Leave the current speed unchanged
      } else if (hasUp) {
        velocity.y = -runSpeed;
      } else if (hasDown) {
        velocity.y = runSpeed;
      } else {
        velocity.y = 0;
      }
    }

    return true;
  }
}
