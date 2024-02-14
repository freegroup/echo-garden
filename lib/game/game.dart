import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/actors/player.dart';
import 'package:echo_garden/game/world.dart';
import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/game.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GameVisualization extends FlameGame with HasKeyboardHandlerComponents {
  late final CameraComponent cameraComponent;

  @override
  final WorldVisualization world;
  JoystickComponent? joystick;
  late final JoystickPlayer player;

  GameVisualization({required GameModel gameModel})
      : world = WorldVisualization(gameModel: gameModel) {
    var modelSize = Vector2(kGameConfiguration.tileMap.width, kGameConfiguration.tileMap.width);
    var canvasSize = modelSize * kGameConfiguration.world.tileSize;

    cameraComponent = CameraComponent(world: world);
    gameModel.gameVisualization = this;

    // Check if the platform supports touch and is not macOS
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.macOS) {
      final knobPaint = BasicPalette.darkGreen.withAlpha(100).paint();
      final backgroundPaint = BasicPalette.green.withAlpha(30).paint();
      joystick = JoystickComponent(
        knob: CircleComponent(radius: 30, paint: knobPaint),
        background: CircleComponent(radius: 100, paint: backgroundPaint),
        margin: const EdgeInsets.only(right: 40, bottom: 40),
      );
    }

    player = JoystickPlayer(gameModel: gameModel, position: canvasSize / 2, joystick: joystick);

    world.add(player);
    if (joystick != null) {
      cameraComponent.viewport.add(joystick!); // Add joystick if not null
    }

    cameraComponent.follow(player);
  }

  @override
  Future<void> onLoad() async {
    await images.loadAll([
      'player.png',
      'ember.png',
      'rabbit-01.png',
      'beach-01.png',
      'beach-02.png',
      'fir-01.png',
      'fir-02.png',
      'fir-03.png',
      'fir-04.png',
      'grass-01.png',
      'grass-02.png',
      'soil-01.png',
      'soil-02.png',
      'tree-01.png',
      'tree-02.png',
      'tree-03.png',
      'tree-04.png',
      'water-01.png',
      'water-02.png',
      'water-beach-01.png',
      'water-beach-02.png',
    ]);

    addAll([cameraComponent, world]);
  }

  Future<void> onModelAdded(AgentModel agent) async {
    await world.onModelAdded(agent);
  }

  Future<void> onModelRemoved(AgentModel agent) async {
    world.onModelRemoved(agent);
  }

  Future<void> onModelMoved(AgentModel agent) async {
    world.onModelMoved(agent);
  }
}
