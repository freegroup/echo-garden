import 'dart:math';

import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/clock.dart';
import 'package:echo_garden/model/direction.dart';

/// The air on one cell. Air is everywhere, one air object per cell, like the
/// soil below it.
///
/// Air is a multi-parameter object: fine dust, humidity, temperature and
/// wind. This base class only holds the values. What the air does in a step
/// is decided by each kind of air itself (sea, land, mountain, coast,
/// foothill); there is no shared rule.
abstract class AirModel extends AgentModel {
  static String staticLayerId = "$AirModel";

  // fine dust (Feinstaub), never below zero
  double _dust = 0;

  double humidity; // Luftfeuchtigkeit, 0..1
  double temperature; // Wärme

  // the wind: one of eight directions and a strength (0 = calm)
  Direction windDirection;
  double windStrength;

  // each kind of air hands in its own start values
  AirModel({
    required super.gameModelRef,
    required super.cell,
    required this.humidity,
    required this.temperature,
  })  : windDirection = Direction.north,
        windStrength = 0;

  @override
  String get layerId => AirModel.staticLayerId;

  @override
  ClockKind get clock => ClockKind.air;

  double get dust => _dust;

  /// Changes the dust by [amount] (negative to remove); never goes below zero.
  /// A source (factory) adds, a sink (tree, moss) subtracts.
  void addDust(double amount) {
    _dust = max(0, _dust + amount);
  }

  // the wind as a vector: direction (length 1) times strength
  double get windX => windDirection.unitX * windStrength;
  double get windY => windDirection.unitY * windStrength;

  /// Sets the direction and the strength of the wind.
  void setWind(Direction direction, double strength) {
    windDirection = direction;
    windStrength = strength;
  }
}
