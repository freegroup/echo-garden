import 'package:echo_garden/game/game.dart';
import 'package:echo_garden/game/world.dart';
import 'package:echo_garden/input/touch_input_device.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/representation/representation.dart';

/// Shows the model on the screen, drawn with Flame.
class GraphicsRepresentation extends Representation {
  late final GameVisualization game;

  GraphicsRepresentation(super.model, super.player, {TouchInputDevice? touchInput}) {
    game = GameVisualization(gameModel: model, player: player, joystick: touchInput?.joystick);
  }

  WorldVisualization get _world => game.world;

  @override
  void syncAll() {
    _world.resync();
  }

  @override
  void onAgentAdded(AgentModel agent) {
    _world.showIfVisible(agent);
  }

  @override
  void onAgentRemoved(AgentModel agent) {
    _world.hide(agent);
  }

  @override
  void onAgentMoved(AgentModel agent) {
    _world.refresh(agent);
  }

  @override
  void onAgentChanged(AgentModel agent) {
    _world.refresh(agent);
  }
}
