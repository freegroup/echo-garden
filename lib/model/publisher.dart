import 'dart:typed_data';

import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/messages.dart';

/// Listens to the model and packs what happens into messages for the readers
/// (see messages.dart): one snapshot at the start, then an update whenever the
/// readers ask for one.
///
/// The air is not sent object by object (there is one per cell): its wind goes
/// as one WindState after the air has taken a step.
class ModelPublisher implements ModelListener {
  final GameModel model;

  // the id of every object the readers know; the objects have no id of their own
  final Map<AgentModel, int> _ids = {};
  int _nextId = 0;

  final List<AgentEvent> _events = [];

  // the air step whose wind was sent last
  int _airStepsSent;

  ModelPublisher(this.model) : _airStepsSent = model.airSteps {
    model.addListener(this);
  }

  WorldSnapshot snapshot() {
    _events.clear();

    List<AgentState> agents = [];
    for (MapEntry<String, Layer> layer in model.layersMap.entries) {
      if (layer.key == AirModel.staticLayerId) continue;
      for (int x = 0; x < model.width; x++) {
        for (int y = 0; y < model.height; y++) {
          AgentModel? agent = layer.value.get(Cell(x, y));
          if (agent != null) {
            agents.add(_stateOf(agent));
          }
        }
      }
    }

    _airStepsSent = model.airSteps;
    return WorldSnapshot(
      width: model.width,
      height: model.height,
      agents: agents,
      wind: _windState(),
    );
  }

  WorldUpdate takeUpdate() {
    List<AgentEvent> events = List.of(_events);
    _events.clear();

    WindState? wind;
    if (model.airSteps != _airStepsSent) {
      _airStepsSent = model.airSteps;
      wind = _windState();
    }
    return WorldUpdate(events: events, wind: wind);
  }

  AgentState _stateOf(AgentModel agent) {
    int id = _ids.putIfAbsent(agent, () => _nextId++);
    return AgentState(
      id: id,
      type: agent.runtimeType,
      layerId: agent.layerId,
      cell: agent.cell,
      energy: agent.energy,
    );
  }

  WindState _windState() {
    Uint8List directions = Uint8List(model.width * model.height);
    Float32List strengths = Float32List(model.width * model.height);
    Layer air = model.getLayer(AirModel.staticLayerId);
    for (int x = 0; x < model.width; x++) {
      for (int y = 0; y < model.height; y++) {
        AgentModel? agent = air.get(Cell(x, y));
        if (agent is AirModel) {
          int index = x * model.height + y;
          directions[index] = agent.windDirection.index;
          strengths[index] = agent.windStrength;
        }
      }
    }
    return WindState(directions: directions, strengths: strengths);
  }

  @override
  void onAgentAdded(AgentModel agent) {
    if (agent.layerId == AirModel.staticLayerId) return;
    _events.add(AgentAdded(_stateOf(agent)));
  }

  @override
  void onAgentRemoved(AgentModel agent) {
    int? id = _ids.remove(agent);
    if (id != null) _events.add(AgentRemoved(id));
  }

  @override
  void onAgentMoved(AgentModel agent) {
    int? id = _ids[agent];
    if (id != null) _events.add(AgentMoved(id, agent.cell));
  }

  @override
  void onAgentChanged(AgentModel agent) {
    int? id = _ids[agent];
    if (id != null) _events.add(AgentChanged(id, agent.energy));
  }
}
