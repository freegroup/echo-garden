import 'package:echo_garden/model/game.dart';
import 'package:echo_garden/model/scheduler/base.dart';
import 'package:flame/components.dart';

class AgentModel {
  static String staticTypeId = "AgentModel";
  late Vector2 cell;
  final BaseScheduler scheduler;

  AgentModel({required this.scheduler, x = 0, y = 0, cell}) {
    if (cell != null) {
      this.cell = cell;
    } else {
      this.cell = Vector2(x, y);
    }
    scheduler.add(this);
  }

  GameModel get gameRef => scheduler.gameRef;

  String get typeId => AgentModel.staticTypeId;

  void preStep() {}

  void step() {}

  void postStep() {}

  void die() {
    gameRef.remove(this);
  }
}
