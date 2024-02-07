import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/actors/player.dart';
import 'package:echo_garden/game/constant.dart';
import 'package:echo_garden/game/game.dart';
import 'package:echo_garden/model/game.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_tiled/flame_tiled.dart';

class EchoGardenWorld extends World with HasGameRef<EchoGardenGame> {
  late TiledComponent _map;
  late GameModel _model;
  late EmberPlayer _player;
  late Vector2 _canvasSize;
  late Vector2 _modelSize;

  EchoGardenWorld({super.children});

  @override
  Future<void> onLoad() async {
    _player = EmberPlayer(position: Vector2(10, 10));
    _map = await TiledComponent.load("world.tmx", Vector2.all(worldTileSize));
    _modelSize = Vector2(_map.tileMap.map.width.toDouble(), _map.tileMap.map.height.toDouble());
    _canvasSize = _modelSize * worldTileSize;
    _model = GameModel(_modelSize);

    addAll([_map, _player]);
    gameRef.cameraComponent.follow(_player);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    setCameraBounds(size);
  }

  void setCameraBounds(Vector2 gameSize) {
    gameRef.cameraComponent.setBounds(
      Rectangle.fromLTRB(
        gameSize.x / 2,
        gameSize.y / 2,
        _canvasSize.x - gameSize.x / 2,
        _canvasSize.y - gameSize.y / 2,
      ),
    );
  }
}
