import 'package:echo_garden/game/world.dart';
import 'package:echo_garden/model/agent.dart';
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
    gameModel.gameVisualization = this;
  }

  @override
  Future<void> onLoad() async {
    await images.loadAll([
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
