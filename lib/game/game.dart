import 'package:echo_garden/game/actors/player.dart';
import 'package:echo_garden/game/world.dart';
import 'package:echo_garden/model/game.dart';
import 'package:echo_garden/player.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

class GameVisualization extends FlameGame {
  late final CameraComponent cameraComponent;

  @override
  final WorldVisualization world;
  late final PlayerSprite player;

  // The joystick of the touch input device, if there is one. It is drawn on
  // top of the world, so it does not move with the camera.
  GameVisualization(
      {required GameModel gameModel, required Player player, JoystickComponent? joystick})
      : world = WorldVisualization(gameModel: gameModel) {
    cameraComponent = CameraComponent(world: world);

    this.player = PlayerSprite(player: player);
    world.add(this.player);

    if (joystick != null) {
      cameraComponent.viewport.add(joystick);
    }

    cameraComponent.follow(this.player);
  }

  GameModel get gameModel => world.gameModel;

  @override
  Future<void> onLoad() async {
    await images.loadAll([
      'player.png',
      'ember.png',
      'rabbit-brown-front.png',
      'rabbit-brown-front-side.png',
      'rabbit-brown-side.png',
      'rabbit-brown-back-side.png',
      'rabbit-brown-back.png',
      'rabbit-grey-front.png',
      'rabbit-grey-front-side.png',
      'rabbit-grey-side.png',
      'rabbit-grey-back-side.png',
      'rabbit-grey-back.png',
      'beach-01.png',
      'beach-02.png',
      'fir-01.png',
      'fir-02.png',
      'fir-03.png',
      'fir-04.png',
      'height-low-01.png',
      'height-low-02.png',
      'height-medium-01.png',
      'height-medium-02.png',
      'height-high-01.png',
      'height-high-02.png',
      'grass-01.png',
      'grass-02.png',
      'soil-01.png',
      'soil-02.png',
      'pine-01.png',
      'pine-02.png',
      'pine-03.png',
      'pine-04.png',
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
}
