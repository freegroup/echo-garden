import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/objects/square.dart';
import 'package:echo_garden/model/game.dart';
import 'package:echo_garden/model/scheduler/base.dart';
import 'package:flame/components.dart';

class AgentModel {
  static String staticLayerId = "AgentModel";
  late Vector2 cell;
  final BaseScheduler scheduler;
  AgentVisualization? _visualization;

  AgentVisualization? get visualization => _visualization;

  set visualization(AgentVisualization? value) {
    _visualization = value;
    _visualization?.onModelChange();
  }

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

  AgentVisualization createVisualization() {
    return ColoredSquare.red(this, cell * kGameConfiguration.world.tileSize);
  }

  void preStep() {}

  void step() {}

  void postStep() {}

  void die() {
    gameModelRef.remove(this);
  }
}
