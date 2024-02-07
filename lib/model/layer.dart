import 'package:echo_garden/utils/intvector2.dart';
import 'package:echo_garden/model/agent.dart';
import 'package:flame/game.dart';

class Layer {
  final List<List<AgentModel?>> _grid; // Changed from Set<T> to T?

  Layer(Vector2 size)
      : _grid = List.generate(
            size.x.toInt(), (_) => List.generate(size.y.toInt(), (_) => null, growable: false),
            growable: false);

  void add(IntVector2 cell, AgentModel item) {
    _grid[cell.x][cell.y] = item; // Directly assign the item to the cell
  }

  AgentModel? get(IntVector2 cell) {
    return _grid[cell.x][cell.y]; // Return the item or null if the cell is empty
  }

  void remove(IntVector2 cell) {
    _grid[cell.x][cell.y] = null; // Clear the cell by setting it to null
  }

  void removeAgent(AgentModel agent) {
    var cell = agent.cell;
    if (_grid[cell.x][cell.y] == agent) {
      _grid[cell.x][cell.y] = null;
    }
  }

  void move(AgentModel agent, IntVector2 newCell) {
    var cell = agent.cell;
    if (_grid[cell.x][cell.y] == agent) {
      _grid[cell.x][cell.y] = null;
      _grid[newCell.x][newCell.y] = agent;
    }
  }
}
