import 'dart:math';
import 'dart:ui';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/game.dart';
import 'package:echo_garden/game/layer.dart';
import 'package:echo_garden/main.dart';
import 'package:echo_garden/model/index.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/material.dart';

class WorldVisualization extends World with HasGameRef<GameVisualization> {
  final GameModel gameModel;

  late Vector2 _canvasSize;
  late Vector2 _modelSize;

  final Set<AgentModel> _visibleModels = <AgentModel>{};
  double _elapsedTime = 0.0;
  final double _updateInterval = 1.3; // 100 milliseconds

  Rect _cellToShow = const Rect.fromLTWH(0, 0, 0, 0);
  late Map<String, TileLayer> _layersMap;

  WorldVisualization({required this.gameModel}) {
    _modelSize = Vector2(kGameConfiguration.tileMap.width, kGameConfiguration.tileMap.width);
    _canvasSize = _modelSize * kGameConfiguration.world.tileSize;

    _layersMap = {
      PatchModel.staticLayerId: TileLayer(priority: 0),
      SeedableModel.staticLayerId: TileLayer(priority: 1),
      PlantModel.staticLayerId: TileLayer(priority: 2),
      ActorModel.staticLayerId: TileLayer(priority: 3),
    };
  }

  @override
  Future<void> onLoad() async {
    addAll([..._layersMap.values]);

    setCellsToShow(Rect.fromLTWH(
      0,
      0,
      kGameConfiguration.world.visibleTileRadius,
      kGameConfiguration.world.visibleTileRadius,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsedTime += dt;
    if (_elapsedTime >= _updateInterval) {
      gameModel.step();
      _elapsedTime -= _updateInterval;
    }
  }

  void setCellsToShow(Rect cells) {
    final stopwatch = Stopwatch()..start();

    double radius = kGameConfiguration.world.visibleTileRadius;

    // snap to multiple of 5 to avoid too much updates of the tilemap
    //
    double alignment = kGameConfiguration.world.tileSnap;
    double alignedLeft = cells.left ~/ alignment * alignment;
    double alignedTop = cells.top ~/ alignment * alignment;

    alignedLeft = max(0, alignedLeft);
    alignedTop = max(0, alignedTop);

    alignedLeft = min(kGameConfiguration.tileMap.width - radius - 1, alignedLeft);
    alignedTop = min(kGameConfiguration.tileMap.height - radius - 1, alignedTop);

    cells = Rect.fromLTWH(alignedLeft, alignedTop, radius, radius);

    if (cells == _cellToShow) {
      return;
    }

    _cellToShow = cells;

    final removeStart = stopwatch.elapsedMilliseconds;
    _visibleModels.removeWhere((agentModel) {
      try {
        if (_cellToShow.containsNotVector2(agentModel.cell)) {
          agentModel.visualization?.removeFromParent();
          agentModel.visualization = null;
          return true;
        }
        return false;
      } catch (e) {
        print(e);
      }
      return true;
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

        // Fill up all visualization layers with the corresponding Model representations
        //
        for (var entry in _layersMap.entries) {
          final layerId = entry.key;
          final layer = entry.value;

          try {
            // Get the model for the layer at the cell
            final agentModel = gameModel.getAgentAtCell(cell, layerId);
            // Check if there is a model and not already a visualization is present
            if (agentModel != null && !_visibleModels.contains(agentModel)) {
              layer.add(agentModel.createVisualization());
              _visibleModels.add(agentModel);
            }
          } catch (e) {
            print(e);
          }
        }
      }
    }

    final addingEnd = stopwatch.elapsedMilliseconds;
    print('Time to add new components: ${addingEnd - addingStart}ms');

    stopwatch.stop();
    print('Total operation time: ${stopwatch.elapsedMilliseconds}ms');
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

  Future<void> onModelAdded(AgentModel agent) async {
    // check if the agent in the visible area.
    //
    if (_cellToShow.containsVector2(agent.cell)) {
      //It can't be in the "_visibleModels", because it is
      //created right now. Assert this
      assert(!_visibleModels.contains(agent));
      await (_layersMap[agent.layerId]!.add(agent.createVisualization()));
      _visibleModels.add(agent);
    }
  }

  Future<void> onModelRemoved(AgentModel agent) async {
    bool hasVis = agent.visualization != null;

    // is is not mandatory, that the model is in the current viewport.
    // in this case the visualization is null...
    agent.visualization?.removeFromParent();
    agent.visualization = null;
    // ...and not part in the _visibleModels set.
    bool hasRemoved = _visibleModels.remove(agent);

    // assert that the model was part of the _visibleModel if it has a visualization
    assert(hasVis == hasRemoved);
  }

  Future<void> onModelMoved(AgentModel agent) async {
    //
  }
}
