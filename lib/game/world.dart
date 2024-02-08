import 'dart:ui';

import 'package:echo_garden/game/actors/player.dart';
import 'package:echo_garden/game/constant.dart';
import 'package:echo_garden/game/game.dart';
import 'package:echo_garden/game/layer.dart';
import 'package:echo_garden/game/objects/square.dart';
import 'package:echo_garden/game/objects/tile.dart';
import 'package:echo_garden/main.dart';
import 'package:echo_garden/model/index.dart' as model;
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/material.dart';

class EchoGardenWorld extends World with HasGameRef<EchoGardenGame> {
  //late TiledComponent _map;
  late model.GameModel _model;
  late EmberPlayer _player;
  late Vector2 _canvasSize;
  late Vector2 _modelSize;
  final Map<Vector2, PositionComponent> _squareComponents = {};
  late TileLayer _tileLayer;

  Rect _cellToShow = const Rect.fromLTWH(0, 0, 0, 0);

  EchoGardenWorld({super.children});
  set cellsToShow(Rect cells) {
    if (cells == _cellToShow) {
      return;
    }

    _cellToShow = cells;

    // Collect keys of squares to remove
    var keysToRemove = <Vector2>[];
    _squareComponents.forEach((cell, square) {
      if (!_cellToShow.contains(Offset(cell.x, cell.y))) {
        _tileLayer.remove(square); // Remove the component from the world
        keysToRemove.add(cell); // Add the key to the removal list
      }
    });

    // Now remove the keys from _squareComponents
    for (var cell in keysToRemove) {
      _squareComponents.remove(cell);
    }

    // Add new components for cells now within cellsToShow
    for (var entry in _model.getLayer(model.PatchModel.staticTypeId).getNonEmptyCellsAndAgents()) {
      Vector2 cell = entry.key;
      model.AgentModel agent = entry.value;

      if (_cellToShow.containsVector2(cell) && !_squareComponents.containsKey(cell)) {
        late PositionComponent newComponent;
        if (agent is model.WaterModel) {
          newComponent = ColoredSquare.blue(cell * worldTileSize);
        } else {
          newComponent =
              TileSquare(position: cell * worldTileSize, spritePosition: Vector2(128, 32));
        }
        _tileLayer.add(newComponent); // Assuming 'add' adds the component to the world
        _squareComponents[cell] = newComponent; // Track the new component
      }
    }
  }

  @override
  Future<void> onLoad() async {
    _tileLayer = TileLayer(priority: 0);
    _player = EmberPlayer(position: Vector2(10, 10));
    _modelSize = Vector2(worldMapSizeWidth, worldMapSizeHeight);
    _canvasSize = _modelSize * worldTileSize;
    _model = model.GameModel(_modelSize);

    addAll([_tileLayer, _player]);

    gameRef.cameraComponent.follow(_player);
    cellsToShow = const Rect.fromLTWH(0, 0, worldLoadedRadius, worldLoadedRadius);
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
