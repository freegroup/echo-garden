import 'dart:math';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/objects/square.dart';
import 'package:echo_garden/model/game.dart';
import 'package:flame/components.dart';

Vector2 zero = Vector2.all(0);

class AgentModel {
  static String staticLayerId = "$AgentModel";
  Vector2 cell;
  double _energy;
  double minEnergy;

  final GameModel gameModelRef;
  AgentVisualization? visualization;

  AgentModel(
      {required this.gameModelRef, required this.cell, double energy = 0, this.minEnergy = 0})
      : _energy = energy;

  // GameModel get gameModelRef => scheduler.gameModelRef;
  String get layerId => AgentModel.staticLayerId;

  double get energy => _energy;

  set energy(double value) {
    _energy = max(minEnergy, value);
  }

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
