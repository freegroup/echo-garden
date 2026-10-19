import 'package:echo_garden/game/game.dart';
import 'package:echo_garden/game/world.dart';
import 'package:echo_garden/representation/representation.dart';
import 'package:echo_garden/representation/world_view.dart';
import 'package:flutter/services.dart';

/// Shows the model on the screen, drawn with Flame.
class GraphicsRepresentation extends Representation {
  late final GameVisualization game;

  GraphicsRepresentation(super.worldView, super.player) {
    game = GameVisualization(worldView: worldView, player: player);
  }

  WorldVisualization get _world => game.world;

  @override
  void wake() {
    super.wake();
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
  }

  @override
  void sleep() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    super.sleep();
  }

  // The D key switches the debug view (the wind arrows) on and off. This only
  // changes what is shown, so it belongs to the graphics, not to the input
  // devices that move the player.
  bool _onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyD) {
      _world.toggleWindArrows();
    }
    // let other parts of the app see the key as well
    return false;
  }

  @override
  void syncAll() {
    _world.resync();
  }

  @override
  void onAgentAdded(AgentView agent) {
    _world.showIfVisible(agent);
  }

  @override
  void onAgentRemoved(AgentView agent) {
    _world.hide(agent);
  }

  @override
  void onAgentMoved(AgentView agent) {
    _world.refresh(agent);
  }

  @override
  void onAgentChanged(AgentView agent) {
    _world.refresh(agent);
  }
}
