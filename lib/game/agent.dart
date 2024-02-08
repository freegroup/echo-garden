/* it is the visual reprensentation Twin of an AgentModel 
*/
import 'package:echo_garden/model/agent.dart';
import 'package:flame/components.dart';

class AgentVisualization extends PositionComponent {
  final AgentModel agentModel;
  AgentVisualization({
    required this.agentModel,
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
}
