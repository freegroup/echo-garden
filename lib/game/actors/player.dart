import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/game.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/objects/beach.dart';
import 'package:echo_garden/game/sound_env.dart';
import 'package:echo_garden/strategy/base.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';

// Update the sound based on proximity to the nearest BeachModel within a maximum radius.
int _maxRadiusTiles = 6;
double _tileSize = kGameConfiguration.world.tileSize;
double _maxRadiusPixel = _maxRadiusTiles * _tileSize;
Vector2 _halfTile = Vector2.all(_tileSize / 2.0); // Calculate once and reuse

class EmberPlayer extends SpriteAnimationComponent
    with HasGameReference<GameVisualization>, KeyboardHandler {
  late final Vector2 velocity;
  final double runSpeed = 250.0;
  late MovementStrategy _strategy;

  EmberPlayer({
    required super.position,
    required GameModel gameModel,
  }) : super(size: Vector2.all(kGameConfiguration.world.tileSize), anchor: Anchor.center) {
    velocity = Vector2(0, 0);
    priority = 100;
    _strategy = MovementStrategy(model: gameModel);
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
    if (velocity.isZero()) {
      return;
    }
    position += velocity * dt;

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

    adjustNearestSound(cellPlayer, PatchModel.staticLayerId, BeachModel, Sound.ocean);
    double maxPossibleEnergy =
        kGameConfiguration.plant.tree.maxEnergy * (_maxRadiusTiles * _maxRadiusTiles - 1);
    adjustAggregatedSound(
        cellPlayer, PlantModel.staticLayerId, TreeModel, 200, maxPossibleEnergy, Sound.blackForest);

    super.update(dt);
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
