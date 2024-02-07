import 'package:echo_garden/game/actors/player.dart';
import 'package:echo_garden/game/constant.dart';
import 'package:echo_garden/game/game.dart';
import 'package:echo_garden/game/objects/square.dart';
import 'package:echo_garden/model/index.dart' as model;
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_tiled/flame_tiled.dart';

class EchoGardenWorld extends World with HasGameRef<EchoGardenGame> {
  late TiledComponent _map;
  late model.GameModel _model;
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
    _model = model.GameModel(_modelSize);

    model.Layer layer = _model.getLayer(model.PatchModel.staticTypeId);
    for (var entry in layer.getNonEmptyCellsAndAgents()) {
      Vector2 cell = entry.key;
      model.AgentModel agent = entry.value;
      ColoredSquare square = ColoredSquare.red(cell * 64);
      add(square);
    }
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
