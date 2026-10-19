import 'package:echo_garden/representation/graphics/sprites/sprite_player.dart';
import 'package:echo_garden/representation/graphics/world.dart';
import 'package:echo_garden/session/player.dart';
import 'package:echo_garden/representation/world_view.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

class GameVisualization extends FlameGame {
  late final CameraComponent cameraComponent;

  @override
  final WorldVisualization world;
  late final SpritePlayer player;

  GameVisualization({required WorldView worldView, required Player player})
      : world = WorldVisualization(worldView: worldView) {
    cameraComponent = CameraComponent(world: world);

    this.player = SpritePlayer(player: player);
    world.add(this.player);

    cameraComponent.follow(this.player);
  }

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
      'grass-05.png',
      'grass-06.png',
      'grass-07.png',
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
