import 'package:echo_garden/game/world.dart';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';

class EchoGardenGame extends FlameGame with HasKeyboardHandlerComponents {
  late final CameraComponent cameraComponent;

  @override
  final EchoGardenWorld world = EchoGardenWorld();

  EchoGardenGame() {
    cameraComponent = CameraComponent(world: world);
  }

  @override
  Future<void> onLoad() async {
    await images.loadAll([
      'block.png',
      'ember.png',
    ]);

    addAll([cameraComponent, world]);
  }
}
