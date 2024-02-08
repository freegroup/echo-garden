import 'package:echo_garden/game/world.dart';
import 'package:echo_garden/model/game.dart';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';

class GameVisualization extends FlameGame with HasKeyboardHandlerComponents {
  late final CameraComponent cameraComponent;

  @override
  final WorldVisualization world;

  GameVisualization({required GameModel gameModel})
      : world = WorldVisualization(gameModel: gameModel) {
    cameraComponent = CameraComponent(world: world);
  }

  @override
  Future<void> onLoad() async {
    await images.loadAll([
      'ember.png',
      'world.png',
    ]);

    addAll([cameraComponent, world]);
  }
}
