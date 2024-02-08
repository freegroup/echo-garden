import 'dart:ui';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/actors/player.dart';

import 'package:echo_garden/game/game.dart';
import 'package:echo_garden/game/layer.dart';
import 'package:echo_garden/game/objects/grass.dart';
import 'package:echo_garden/game/objects/water.dart';
import 'package:echo_garden/main.dart';
import 'package:echo_garden/model/index.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/material.dart';

class WorldVisualization extends World with HasGameRef<GameVisualization> {
  final GameModel gameModel;
  late EmberPlayer _player;
  late Vector2 _canvasSize;
  late Vector2 _modelSize;
  final Map<Vector2, PositionComponent> _squareComponents = {};
  late TileLayer _tileLayer;

  Rect _cellToShow = const Rect.fromLTWH(0, 0, 0, 0);

  WorldVisualization({required this.gameModel, super.children}) {
    _modelSize = Vector2(kGameConfiguration.tileMap.width, kGameConfiguration.tileMap.width);
    _canvasSize = _modelSize * kGameConfiguration.world.tileSize;
  }

  set cellsToShow(Rect cells) {
    final stopwatch = Stopwatch()..start();

    if (cells == _cellToShow) {
      return;
    }

    _cellToShow = cells;

    final removeStart = stopwatch.elapsedMilliseconds;
    _squareComponents.removeWhere((cell, square) {
      final shouldRemove = !_cellToShow.containsVector2(cell);
      if (shouldRemove) {
        _tileLayer.remove(square);
      }
      return shouldRemove;
    });
    final removeEnd = stopwatch.elapsedMilliseconds;
    print('Time to remove squares: ${removeEnd - removeStart}ms');

    // Add new components for cells now within cellsToShow
    final addingStart = stopwatch.elapsedMilliseconds;

    // Calculate the range of cells within the visible area
    int startX = _cellToShow.left.floor();
    int startY = _cellToShow.top.floor();
    int endX = _cellToShow.right.ceil();
    int endY = _cellToShow.bottom.ceil();

    // Adjust the iteration to only cover cells within the visible area
    for (int x = startX; x <= endX; x++) {
      for (int y = startY; y <= endY; y++) {
        // Convert grid indices to Vector2 for compatibility with the rest of your code
        Vector2 cell = Vector2(x.toDouble(), y.toDouble());

        // Check if there's an agent at this cell and if it's not already represented by a component
        final agent = gameModel.getLayer(PatchModel.staticTypeId).get(cell);
        if (agent != null && !_squareComponents.containsKey(cell)) {
          late PositionComponent newComponent;
          if (agent is WaterModel) {
            newComponent = WaterTile(position: cell * kGameConfiguration.world.tileSize);
          } else {
            newComponent = GrassTile(position: cell * kGameConfiguration.world.tileSize);
          }
          _tileLayer.add(newComponent);
          _squareComponents[cell] = newComponent;
        }
      }
    }

    final addingEnd = stopwatch.elapsedMilliseconds;
    print('Time to add new components: ${addingEnd - addingStart}ms');

    stopwatch.stop();
    print('Total operation time: ${stopwatch.elapsedMilliseconds}ms');
  }

  @override
  Future<void> onLoad() async {
    _tileLayer = TileLayer(priority: 0);
    _player = EmberPlayer(position: Vector2(10, 10));

    addAll([_tileLayer, _player]);

    gameRef.cameraComponent.follow(_player);
    cellsToShow = Rect.fromLTWH(
      0,
      0,
      kGameConfiguration.world.visibleTileRadius,
      kGameConfiguration.world.visibleTileRadius,
    );
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
