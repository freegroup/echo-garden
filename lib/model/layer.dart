import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/cell.dart';

/// One layer of the map: at most one agent per cell.
class Layer {
  final int width;
  final int height;
  final List<List<AgentModel?>> _grid;

  Layer(this.width, this.height)
      : _grid = List.generate(
            width, (_) => List.generate(height, (_) => null, growable: false),
            growable: false);

  bool _isInside(Cell cell) {
    return cell.x >= 0 && cell.y >= 0 && cell.x < width && cell.y < height;
  }

  void add(Cell cell, AgentModel item) {
    assert(_grid[cell.x][cell.y] == null, '$cell is already occupied');
    _grid[cell.x][cell.y] = item;
  }

  /// The agent on the cell, or null. Cells outside of the map are empty.
  AgentModel? get(Cell cell) {
    if (!_isInside(cell)) {
      return null;
    }
    return _grid[cell.x][cell.y];
  }

  bool remove(AgentModel agent) {
    Cell cell = agent.cell;
    if (_grid[cell.x][cell.y] == agent) {
      _grid[cell.x][cell.y] = null;
      return true;
    }
    return false;
  }

  bool move(AgentModel agent, Cell newCell) {
    Cell oldCell = agent.cell;
    if (_grid[oldCell.x][oldCell.y] == agent) {
      _grid[oldCell.x][oldCell.y] = null;
      assert(_grid[newCell.x][newCell.y] == null, '$newCell is already occupied');
      _grid[newCell.x][newCell.y] = agent;
      return true;
    }
    return false;
  }

  Iterable<MapEntry<Cell, AgentModel>> getNonEmptyCellsAndAgents() sync* {
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        AgentModel? agent = _grid[x][y];
        if (agent != null) {
          yield MapEntry(Cell(x, y), agent);
        }
      }
    }
  }
}
