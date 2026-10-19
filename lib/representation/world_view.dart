import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/messages.dart';

/// One object of the world, as the readers know it from the messages.
class AgentView {
  final int id;
  final Type type;
  final String layerId;
  Cell cell;
  double energy;

  AgentView(AgentState state)
      : id = state.id,
        type = state.type,
        layerId = state.layerId,
        cell = state.cell,
        energy = state.energy;
}

/// Who wants to hear what changes in the world.
abstract class WorldViewListener {
  void onAgentAdded(AgentView agent);

  void onAgentRemoved(AgentView agent);

  void onAgentMoved(AgentView agent);

  /// The state of the object changed, e.g. its energy.
  void onAgentChanged(AgentView agent);
}

/// What the user interface knows about the world. It is built only from the
/// messages of the model (see messages.dart), never from the model itself, so
/// the model can run in an isolate of its own.
///
/// The graphics, the sound and the player ask it what is where, and it answers
/// right away from what the messages said.
class WorldView {
  final int width;
  final int height;

  // per layer the object of every cell; the cell (x, y) is at x * height + y
  final Map<String, List<AgentView?>> _layers = {};
  final Map<int, AgentView> _agents = {};
  WindState _wind;

  final List<WorldViewListener> _listeners = [];

  WorldView(WorldSnapshot snapshot)
      : width = snapshot.width,
        height = snapshot.height,
        _wind = snapshot.wind {
    for (AgentState state in snapshot.agents) {
      _place(AgentView(state));
    }
  }

  void addListener(WorldViewListener listener) {
    _listeners.add(listener);
  }

  void removeListener(WorldViewListener listener) {
    _listeners.remove(listener);
  }

  /// Takes in what happened, in the same order as in the model, and tells the
  /// listeners about it.
  void apply(WorldUpdate update) {
    for (AgentEvent event in update.events) {
      switch (event) {
        case AgentAdded added:
          AgentView agent = AgentView(added.agent);
          _place(agent);
          for (WorldViewListener listener in _listeners) {
            listener.onAgentAdded(agent);
          }
        case AgentRemoved removed:
          AgentView agent = _agents.remove(removed.id)!;
          _layerOf(agent)[_index(agent.cell)] = null;
          for (WorldViewListener listener in _listeners) {
            listener.onAgentRemoved(agent);
          }
        case AgentMoved moved:
          AgentView agent = _agents[moved.id]!;
          _layerOf(agent)[_index(agent.cell)] = null;
          agent.cell = moved.cell;
          _layerOf(agent)[_index(agent.cell)] = agent;
          for (WorldViewListener listener in _listeners) {
            listener.onAgentMoved(agent);
          }
        case AgentChanged changed:
          AgentView agent = _agents[changed.id]!;
          agent.energy = changed.energy;
          for (WorldViewListener listener in _listeners) {
            listener.onAgentChanged(agent);
          }
      }
    }

    WindState? wind = update.wind;
    if (wind != null) {
      _wind = wind;
    }
  }

  /// The object on a layer at a cell, or null. Cells outside of the map are empty.
  AgentView? agentAt(Cell cell, String layerId) {
    if (!_isInside(cell)) return null;
    return _layers[layerId]?[_index(cell)];
  }

  /// The type of the topmost ground of a cell, as GameModel.groundTypeAt: a
  /// mountain, else the soil, else water or beach. Null outside of the map.
  Type? groundTypeAt(Cell cell) {
    for (String layerId in [
      HeightAreaModel.staticLayerId,
      SeedableModel.staticLayerId,
      PatchModel.staticLayerId,
    ]) {
      AgentView? ground = agentAt(cell, layerId);
      if (ground != null) {
        return ground.type;
      }
    }
    return null;
  }

  /// The wind of a cell, as of the last air step. Null outside of the map.
  ({Direction direction, double strength})? windAt(Cell cell) {
    if (!_isInside(cell)) return null;
    int index = _index(cell);
    return (
      direction: Direction.values[_wind.directions[index]],
      strength: _wind.strengths[index],
    );
  }

  /// The nearest cell around [cell] (not the cell itself) with an object of
  /// exactly [type], as MovementStrategy.getNearestCellForAgentTypeOnLayer.
  Cell? nearestCellOf({
    required Cell cell,
    required int radius,
    required Type type,
    required String layerId,
  }) {
    double nearestDistance = -1;
    Cell? nearestCell;
    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        if (dx == 0 && dy == 0) continue; // not the cell itself

        Cell around = Cell(cell.x + dx, cell.y + dy);
        AgentView? agent = agentAt(around, layerId);
        if (agent != null && agent.type == type) {
          double distance = cell.distanceTo(around);
          if (nearestDistance == -1 || distance < nearestDistance) {
            nearestDistance = distance;
            nearestCell = around;
          }
        }
      }
    }
    return nearestCell;
  }

  /// The energy of all objects of exactly [type] around [cell] (not the cell
  /// itself), as MovementStrategy.getAggregatedEnergyForAgentTypeOnLayer.
  double energyAround({
    required Cell cell,
    required int radius,
    required Type type,
    required String layerId,
  }) {
    double energy = 0;
    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        if (dx == 0 && dy == 0) continue; // not the cell itself

        AgentView? agent = agentAt(Cell(cell.x + dx, cell.y + dy), layerId);
        if (agent != null && agent.type == type) {
          energy += agent.energy;
        }
      }
    }
    return energy;
  }

  void _place(AgentView agent) {
    _agents[agent.id] = agent;
    _layerOf(agent)[_index(agent.cell)] = agent;
  }

  List<AgentView?> _layerOf(AgentView agent) {
    return _layers.putIfAbsent(agent.layerId, () => List.filled(width * height, null));
  }

  bool _isInside(Cell cell) {
    return cell.x >= 0 && cell.y >= 0 && cell.x < width && cell.y < height;
  }

  int _index(Cell cell) => cell.x * height + cell.y;
}
