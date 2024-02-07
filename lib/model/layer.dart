import 'package:echo_garden/model/agent.dart';
import 'package:flame/game.dart';

class _IntVector2 {
  final int x;
  final int y;
  _IntVector2(this.x, this.y);
}

_IntVector2 _toIntVector2(Vector2 v) {
  return _IntVector2(v.x.toInt(), v.y.toInt());
}

class Layer {
  final List<List<AgentModel?>> _grid; // Changed from Set<T> to T?

  Layer(Vector2 size)
      : _grid = List.generate(
            size.x.toInt(), (_) => List.generate(size.y.toInt(), (_) => null, growable: false),
            growable: false);
  void add(Vector2 cell, AgentModel item) {
    final ivCell = _toIntVector2(cell);
    _grid[ivCell.x][ivCell.y] = item;
  }

  AgentModel? get(Vector2 cell) {
    final ivCell = _toIntVector2(cell);
    return _grid[ivCell.x][ivCell.y];
  }

  void remove(Vector2 cell) {
    final ivCell = _toIntVector2(cell);
    _grid[ivCell.x][ivCell.y] = null;
  }

  void removeAgent(AgentModel agent) {
    final cell = _toIntVector2(agent.cell);
    if (_grid[cell.x][cell.y] == agent) {
      _grid[cell.x][cell.y] = null;
    }
  }

  void move(AgentModel agent, Vector2 newCell) {
    final oldCell = _toIntVector2(agent.cell);
    final ivNewCell = _toIntVector2(newCell);
    if (_grid[oldCell.x][oldCell.y] == agent) {
      _grid[oldCell.x][oldCell.y] = null;
      _grid[ivNewCell.x][ivNewCell.y] = agent;
    }
  }

  Iterable<MapEntry<Vector2, AgentModel>> getNonEmptyCellsAndAgents() sync* {
    for (int x = 0; x < _grid.length; x++) {
      for (int y = 0; y < _grid[x].length; y++) {
        var agent = _grid[x][y];
        if (agent != null) {
          var cell = Vector2(x.toDouble(), y.toDouble());
          yield MapEntry(cell, agent);
        }
      }
    }
  }
}
