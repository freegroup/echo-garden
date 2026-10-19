import 'dart:math';
import 'dart:ui';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/game.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/air_debug_renderer.dart';
import 'package:echo_garden/game/ground_renderer.dart';
import 'package:echo_garden/game/layer.dart';
import 'package:echo_garden/game/pixels.dart';
import 'package:echo_garden/game/visualization_factory.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/representation/world_view.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/material.dart';

/// Draws the tiles of the model.
///
/// To keep the game fast, only agents in the visible area get a tile.
/// The GraphicsRepresentation tells the world when agents change.
class WorldVisualization extends World with HasGameRef<GameVisualization> {
  final WorldView worldView;

  late Vector2 _canvasSize;

  // the tiles of all agents that are currently shown
  final Map<AgentView, AgentVisualization> _visualizations = {};

  Rect _cellToShow = const Rect.fromLTWH(0, 0, 0, 0);
  late Map<String, TileLayer> _layersMap;
  late final GroundRenderer _groundRenderer;
  late final AirDebugRenderer _airDebugRenderer;

  WorldVisualization({required this.worldView}) {
    _canvasSize = cellToPixel(Cell(kGameConfiguration.grid.mapWidth, kGameConfiguration.grid.mapHeight));

    _groundRenderer = GroundRenderer(worldView: worldView)
      ..priority = 0
      ..size = _canvasSize;

    // the ground is drawn by the ground renderer; these layers hold the
    // per-agent tiles that sit on top of it
    _layersMap = {
      PlantModel.staticLayerId: TileLayer(priority: 3),
      ActorModel.staticLayerId: TileLayer(priority: 4),
    };
  }

  @override
  Future<void> onLoad() async {
    add(_groundRenderer);
    // the wind arrows: above trees and rabbits, below the player (500)
    _airDebugRenderer = AirDebugRenderer(worldView: worldView)
      ..priority = 450
      ..size = _canvasSize;
    add(_airDebugRenderer);
    addAll([..._layersMap.values]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _showCellsInView();
  }

  // Show the cells the camera currently sees, plus one tile of margin.
  void _showCellsInView() {
    final view = gameRef.cameraComponent.visibleWorldRect;
    final tileSize = kGameConfiguration.world.tileSize;
    setCellsToShow(Rect.fromLTRB(
      (view.left / tileSize).floorToDouble() - 1,
      (view.top / tileSize).floorToDouble() - 1,
      (view.right / tileSize).floorToDouble() + 1,
      (view.bottom / tileSize).floorToDouble() + 1,
    ));
  }

  void setCellsToShow(Rect cells) {
    // snap to multiple of 5 to avoid too much updates of the tilemap
    //
    double alignment = kGameConfiguration.world.tileSnap;
    double alignedLeft = cells.left ~/ alignment * alignment;
    double alignedTop = cells.top ~/ alignment * alignment;
    double alignedRight = (cells.right / alignment).ceil() * alignment;
    double alignedBottom = (cells.bottom / alignment).ceil() * alignment;

    alignedLeft = max(0, alignedLeft);
    alignedTop = max(0, alignedTop);

    alignedRight = min(kGameConfiguration.grid.mapWidth - 1, alignedRight);
    alignedBottom = min(kGameConfiguration.grid.mapHeight - 1, alignedBottom);

    cells = Rect.fromLTRB(alignedLeft, alignedTop, alignedRight, alignedBottom);

    if (cells == _cellToShow) {
      return;
    }

    _cellToShow = cells;

    _visualizations.removeWhere((agent, visualization) {
      if (!_isInView(agent.cell)) {
        visualization.removeFromParent();
        return true;
      }
      return false;
    });

    // Calculate the range of cells within the visible area
    int startX = _cellToShow.left.floor();
    int startY = _cellToShow.top.floor();
    int endX = _cellToShow.right.ceil();
    int endY = _cellToShow.bottom.ceil();

    for (int x = startX; x <= endX; x++) {
      for (int y = startY; y <= endY; y++) {
        Cell cell = Cell(x, y);

        // fill the per-agent layers (plants, rabbits) with their tiles
        for (var entry in _layersMap.entries) {
          final agent = worldView.agentAt(cell, entry.key);
          if (agent != null && !isGroundCover(agent) && !_visualizations.containsKey(agent)) {
            _show(agent, entry.value);
          }
        }
      }
    }
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

  // the right and bottom edge belong to the visible area as well
  bool _isInView(Cell cell) {
    return cell.x >= _cellToShow.left &&
        cell.x <= _cellToShow.right &&
        cell.y >= _cellToShow.top &&
        cell.y <= _cellToShow.bottom;
  }

  void _show(AgentView agent, TileLayer layer) {
    AgentVisualization visualization = createVisualization(agent);
    // not awaited: while the tile loads, setCellsToShow must already see the
    // agent as visible, otherwise it would create a second visualization
    layer.add(visualization);
    _visualizations[agent] = visualization;
  }

  /// Shows or hides the wind arrows.
  void toggleWindArrows() {
    _airDebugRenderer.isShown = !_airDebugRenderer.isShown;
  }

  /// Removes all tiles. The next frame creates them again from the world view.
  void resync() {
    for (AgentVisualization visualization in _visualizations.values) {
      visualization.removeFromParent();
    }
    _visualizations.clear();
    _cellToShow = Rect.zero;
  }

  void showIfVisible(AgentView agent) {
    // the ground and the grass are drawn by the ground renderer, not per agent
    TileLayer? layer = _layersMap[agent.layerId];
    if (layer == null || isGroundCover(agent)) return;

    // only agents in the visible area get a tile
    if (_isInView(agent.cell)) {
      // the agent was created right now, so it can't have a tile yet
      assert(!_visualizations.containsKey(agent));
      _show(agent, layer);
    }
  }

  void hide(AgentView agent) {
    // agents outside of the visible area have no tile
    AgentVisualization? visualization = _visualizations.remove(agent);
    visualization?.removeFromParent();
  }

  void refresh(AgentView agent) {
    _visualizations[agent]?.onModelChange();
  }
}
