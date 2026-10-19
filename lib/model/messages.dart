import 'dart:typed_data';

import 'package:echo_garden/model/cell.dart';

// The messages the model sends to its readers: the graphics, the sound, the
// player, later the reporter. The readers know the world only from these
// messages, so the model can run in an isolate of its own.
//
// They are plain data. Types like TreeModel are the shared vocabulary: a type
// can be sent from one isolate to another, a model object cannot.

/// One object of the model, as the readers see it.
class AgentState {
  final int id;
  final Type type;
  final String layerId;
  final Cell cell;
  final double energy;

  const AgentState({
    required this.id,
    required this.type,
    required this.layerId,
    required this.cell,
    required this.energy,
  });
}

/// Something that happened to one object, which is known by its id.
sealed class AgentEvent {
  final int id;

  const AgentEvent(this.id);
}

class AgentAdded extends AgentEvent {
  final AgentState agent;

  AgentAdded(this.agent) : super(agent.id);
}

class AgentRemoved extends AgentEvent {
  const AgentRemoved(super.id);
}

class AgentMoved extends AgentEvent {
  final Cell cell;

  const AgentMoved(super.id, this.cell);
}

class AgentChanged extends AgentEvent {
  final double energy;

  const AgentChanged(super.id, this.energy);
}

/// The wind of every cell. The cell (x, y) is at index x * height + y; the
/// direction is the index in Direction.values.
class WindState {
  final Uint8List directions;
  final Float32List strengths;

  const WindState({required this.directions, required this.strengths});
}

/// Everything there is, when the readers start.
class WorldSnapshot {
  final int width;
  final int height;
  final List<AgentState> agents;
  final WindState wind;

  const WorldSnapshot({
    required this.width,
    required this.height,
    required this.agents,
    required this.wind,
  });
}

/// What happened since the last update, in the order it happened. The wind
/// only comes along when the air has taken a step.
class WorldUpdate {
  final List<AgentEvent> events;
  final WindState? wind;

  const WorldUpdate({required this.events, this.wind});
}
