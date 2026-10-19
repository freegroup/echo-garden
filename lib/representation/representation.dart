import 'package:echo_garden/player.dart';
import 'package:echo_garden/representation/world_view.dart';

/// Base class for everything that makes the model perceivable:
/// graphics, sound, later e.g. vibration or a watch.
///
/// A representation knows the world only from the world view, which is built
/// from the messages of the model. It is either awake (registered for the
/// changes and updated every frame) or asleep (the model keeps running without
/// it, e.g. while catching up after the app was closed).
abstract class Representation implements WorldViewListener {
  final WorldView worldView;

  // the observer: where the camera looks and where the listener stands
  final Player player;

  bool _isAwake = false;

  Representation(this.worldView, this.player);

  bool get isAwake => _isAwake;

  void wake() {
    if (_isAwake) return;
    syncAll();
    worldView.addListener(this);
    _isAwake = true;
  }

  void sleep() {
    if (!_isAwake) return;
    worldView.removeListener(this);
    _isAwake = false;
  }

  /// Brings the representation in line with the current state of the world.
  void syncAll();

  /// Called every frame while awake.
  void update(double dt) {}

  // Changes of the world: by default nothing happens. Each representation
  // overrides the ones it needs.

  @override
  void onAgentAdded(AgentView agent) {}

  @override
  void onAgentRemoved(AgentView agent) {}

  @override
  void onAgentMoved(AgentView agent) {}

  @override
  void onAgentChanged(AgentView agent) {}
}
