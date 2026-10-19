import 'dart:math';

import 'package:echo_garden/model/cell.dart';
import 'package:echo_garden/model/clock.dart';
import 'package:echo_garden/model/game.dart';
import 'package:echo_garden/model/pos.dart';

/// An object of the model that lives on the grid: soil, plants, rabbits, ...
///
/// It always sits on a whole cell. Its position is the middle of that cell.
class AgentModel {
  static String staticLayerId = "$AgentModel";
  Cell cell;
  double _energy;
  double minEnergy;

  final GameModel gameModelRef;

  AgentModel(
      {required this.gameModelRef, required this.cell, double energy = 0, this.minEnergy = 0})
      : _energy = energy;

  String get layerId => AgentModel.staticLayerId;

  /// The clock this object takes its steps on.
  ClockKind get clock => ClockKind.ecology;

  Pos get position => cell.center;

  double get energy => _energy;

  set energy(double value) {
    double newEnergy = max(minEnergy, value);
    if (newEnergy == _energy) return;
    _energy = newEnergy;
    // Every change of the state is reported, so no reader can miss one: the
    // readers know the world only from these reports (see ModelPublisher).
    gameModelRef.notifyChanged(this);
  }

  void step() {
    //
  }
}
