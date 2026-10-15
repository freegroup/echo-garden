import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/player.dart';

/// Base class for everything that makes the model perceivable:
/// graphics, sound, later e.g. vibration or a watch.
///
/// A representation only reads the model. It is either awake (registered for
/// model events and updated every frame) or asleep (the model keeps running
/// without it, e.g. while catching up after the app was closed).
abstract class Representation implements ModelListener {
  final GameModel model;

  // the observer: where the camera looks and where the listener stands
  final Player player;

  bool _isAwake = false;

  Representation(this.model, this.player);

  bool get isAwake => _isAwake;

  void wake() {
    if (_isAwake) return;
    syncAll();
    model.addListener(this);
    _isAwake = true;
  }

  void sleep() {
    if (!_isAwake) return;
    model.removeListener(this);
    _isAwake = false;
  }

  /// Brings the representation in line with the current state of the model.
  void syncAll();

  /// Called every frame while awake.
  void update(double dt) {}

  // Model events: by default nothing happens. Each representation overrides
  // the events it needs.

  @override
  void onAgentAdded(AgentModel agent) {}

  @override
  void onAgentRemoved(AgentModel agent) {}

  @override
  void onAgentMoved(AgentModel agent) {}

  @override
  void onAgentChanged(AgentModel agent) {}
}
