import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/model/game.dart';
import 'package:echo_garden/model/scheduler/base.dart';
import 'package:flame/components.dart';

class AgentModel {
  static String staticLayerId = "AgentModel";
  late Vector2 cell;
  final BaseScheduler scheduler;
  AgentVisualization? visualization;

  AgentModel({required this.scheduler, x = 0, y = 0, cell}) {
    if (cell != null) {
      this.cell = cell;
    } else {
      this.cell = Vector2(x, y);
    }
    scheduler.add(this);
  }

  GameModel get gameModelRef => scheduler.gameModelRef;

  String get layerId => AgentModel.staticLayerId;

  void preStep() {}

  void step() {}

  void postStep() {}

  void die() {
    gameModelRef.remove(this);
  }
}
