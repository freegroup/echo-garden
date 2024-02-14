import 'dart:math';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/game.dart';
import 'package:echo_garden/game/sound_env.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/objects/beach.dart';
import 'package:echo_garden/strategy/base.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

// Update the sound based on proximity to the nearest BeachModel within a maximum radius.
int _maxRadiusTiles = 7;
double _tileSize = kGameConfiguration.world.tileSize;
double _maxRadiusPixel = _maxRadiusTiles * _tileSize;
Vector2 _halfTile = Vector2.all(_tileSize / 2.0); // Calculate once and reuse

class JoystickPlayer extends SpriteAnimationComponent
    with HasGameReference<GameVisualization>, KeyboardHandler {
  late final Vector2 velocity;
  final double runSpeed = 250.0;
  late MovementStrategy _strategy;
  final JoystickComponent? joystick;

  final double _animationSpeed = 0.01;

  late final SpriteAnimation _runDownAnimation;
  late final SpriteAnimation _runLeftAnimation;
  late final SpriteAnimation _runUpAnimation;
  late final SpriteAnimation _runRightAnimation;

  final Vector2 oldPosition = Vector2.all(0);
  JoystickPlayer({
    required super.position,
    this.joystick,
    required GameModel gameModel,
  }) : super(size: Vector2.all(kGameConfiguration.world.tileSize), anchor: Anchor.center) {
    velocity = Vector2(0, 0);
    priority = 100;
    _strategy = MovementStrategy(model: gameModel);
  }

  @override
  void onLoad() {
    final spriteSheet = SpriteSheet(
      image: game.images.fromCache('player.png'),
      srcSize: Vector2(96.0, 96.0),
    );

    _runDownAnimation = spriteSheet.createAnimation(row: 0, stepTime: _animationSpeed, to: 4);
    _runLeftAnimation = spriteSheet.createAnimation(row: 1, stepTime: _animationSpeed, to: 4);
    _runRightAnimation = spriteSheet.createAnimation(row: 2, stepTime: _animationSpeed, to: 4);
    _runUpAnimation = spriteSheet.createAnimation(row: 3, stepTime: _animationSpeed, to: 4);
    animation = _runLeftAnimation;
  }

  void schritteVibration() async {
    bool? canVibrate = await Vibration.hasVibrator();
    if (canVibrate != null && canVibrate) {
      // Erzeuge eine sanfte Vibration
      // Die Dauer der Vibration ist in Millisekunden.
      // Für sanfte Schritte könntest du kurze Vibrationen mit Pausen dazwischen verwenden.
      Vibration.vibrate(duration: 10, amplitude: 20);
    }
  }

  @override
  void update(double dt) {
    // https://github.com/flame-engine/flame/blob/main/examples/lib/stories/input/joystick_player.dart
    if (joystick != null) {
      velocity.x = joystick!.relativeDelta.x * runSpeed;
      velocity.y = joystick!.relativeDelta.y * runSpeed;
    }

    if (velocity.isZero()) {
      return;
    }

    _selectAnimationByVelocity();
    position += velocity * dt;
    if (position.distanceTo(oldPosition) > 80) {
      schritteVibration();
      oldPosition.x = position.x;
      oldPosition.y = position.y;
    }
    Vector2 cellPlayer = (position / kGameConfiguration.world.tileSize)..floor();

    double alignedStartX = cellPlayer.x - kGameConfiguration.world.visibleTileRadius ~/ 2;
    double alignedStartY = cellPlayer.y - kGameConfiguration.world.visibleTileRadius ~/ 2;

    Rect cellsAroundPlayer = Rect.fromLTWH(
      alignedStartX,
      alignedStartY,
      kGameConfiguration.world.visibleTileRadius,
      kGameConfiguration.world.visibleTileRadius,
    );
    // center the rect around the player
    game.world.setCellsToShow(cellsAroundPlayer);

    adjustNearestSound(
      cellPlayer,
      PatchModel.staticLayerId,
      BeachModel,
      Sound.ocean,
    );

    double maxPossibleEnergy =
        kGameConfiguration.plant.tree.maxEnergy * (_maxRadiusTiles * _maxRadiusTiles - 1);
    adjustAggregatedSound(
      cellPlayer,
      PlantModel.staticLayerId,
      TreeModel,
      200,
      maxPossibleEnergy,
      Sound.blackForest,
    );

    super.update(dt);
  }

  void _selectAnimationByVelocity() {
    // Assuming velocity.x and velocity.y are defined elsewhere in your class
    double angleInDegrees = atan2(velocity.y, velocity.x) * (180 / pi);

    // Normalize the angle to [0, 360) range
    angleInDegrees = (angleInDegrees + 360) % 360;

    if ((angleInDegrees > 315 && angleInDegrees <= 360) || (angleInDegrees <= 45)) {
      // Right
      animation = _runRightAnimation;
    } else if (angleInDegrees > 135 && angleInDegrees <= 225) {
      // Left
      animation = _runLeftAnimation;
    } else if (angleInDegrees > 45 && angleInDegrees <= 135) {
      // Up
      animation = _runDownAnimation;
    } else if (angleInDegrees > 225 && angleInDegrees <= 315) {
      // Down
      animation = _runUpAnimation;
    }
  }

  void adjustNearestSound(Vector2 cellPlayer, layerId, Type agentType, Sound sound) {
    var nearestCell = _strategy.getNearestCellForAgentTypeOnLayer(
      cell: cellPlayer,
      type: agentType,
      radius: _maxRadiusTiles,
      layerId: layerId,
    );
    if (nearestCell != null) {
      Vector2 center = nearestCell * _tileSize + _halfTile;
      double distanceToBeach = center.distanceTo(position + _halfTile).clamp(0, _maxRadiusPixel);
      double volume = 1 - (distanceToBeach / _maxRadiusPixel);
      SoundEnvironment.loop(sound, volume);
    } else {
      SoundEnvironment.stop(sound);
    }
  }

  void adjustAggregatedSound(Vector2 cellPlayer, layerId, Type agentType, double energyMinLevel,
      double energyMaxLevel, Sound sound) {
    var aggregatedEnergy = _strategy.getAggregatedEnergyForAgentTypeOnLayer(
      cell: cellPlayer,
      type: agentType,
      radius: _maxRadiusTiles,
      layerId: layerId,
    );
    if (aggregatedEnergy > energyMinLevel) {
      aggregatedEnergy = aggregatedEnergy.clamp(energyMinLevel, energyMaxLevel);
      double volume = ((aggregatedEnergy - energyMinLevel) / (energyMaxLevel - energyMinLevel));
      SoundEnvironment.loop(sound, volume);
    } else {
      SoundEnvironment.stop(sound);
    }
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
