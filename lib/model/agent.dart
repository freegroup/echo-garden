import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/objects/square.dart';
import 'package:echo_garden/model/game.dart';
import 'package:flame/components.dart';

Vector2 zero = Vector2.all(0);

class AgentModel {
  static String staticLayerId = "$AgentModel";
  Vector2 cell;
  double energy;

  final GameModel gameModelRef;
  AgentVisualization? visualization;

  AgentModel({required this.gameModelRef, required this.cell, this.energy = 0});

  // GameModel get gameModelRef => scheduler.gameModelRef;
  String get layerId => AgentModel.staticLayerId;

  AgentVisualization createVisualization() {
    assert(visualization == null);
    return visualization = ColoredSquare.red(
      this,
      cell * kGameConfiguration.world.tileSize,
    );
  }

  Future<void> step() async {
    //
  }
}
