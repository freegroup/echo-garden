/* it is the visual reprensentation Twin of an object of the world view
*/
import 'package:echo_garden/representation/graphics/game.dart';
import 'package:echo_garden/representation/world_view.dart';
import 'package:flame/components.dart';

class AgentVisualization extends PositionComponent with HasGameReference<GameVisualization> {
  final AgentView agent;
  AgentVisualization({
    required this.agent,
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.nativeAngle,
    super.anchor,
    super.children,
    super.priority,
    super.key,
  });

  Future<void> onModelChange() async {}
}
