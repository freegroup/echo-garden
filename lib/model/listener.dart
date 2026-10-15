import 'package:echo_garden/model/agent.dart';

/// Receives notifications about changes in the model.
///
/// Representations (graphics, sound, ...) implement this interface and
/// register themselves with `GameModel.addListener`. The model only informs
/// the listeners and never waits for them, so the simulation works the same
/// with or without any representation attached.
abstract class ModelListener {
  void onAgentAdded(AgentModel agent);

  void onAgentRemoved(AgentModel agent);

  void onAgentMoved(AgentModel agent);

  /// The state of the agent changed, e.g. its energy.
  void onAgentChanged(AgentModel agent);
}
