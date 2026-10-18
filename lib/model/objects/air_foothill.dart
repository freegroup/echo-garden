import 'dart:math';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/direction.dart';
import 'package:echo_garden/model/layer.dart';
import 'package:echo_garden/model/objects/air.dart';

/// Air on flat land at the foot of a mountain: the source of a simulated
/// updraft, the wind blows towards the mountain.
///
/// The updraft does not jump. For a random number of steps it rises (or
/// falls) a little every step, then a new run with a new direction (up or
/// down) and a new length starts. So it changes smoothly instead of
/// flickering.
class AirFoothillModel extends AirModel {
  /// Where the mountain lies, as seen from here; null when there is none.
  /// Handed in by whoever creates the air (the terraformer knows the ground).
  final Direction? mountainward;

  /// The strength of the updraft towards the mountain.
  double updraft = 0;

  int _trend = 1; // +1: the updraft rises, -1: it falls
  int _stepsLeft = 0; // steps left in the current run (incCount)

  AirFoothillModel({required super.gameModelRef, required super.cell, required this.mountainward})
      : super(
          humidity: kGameConfiguration.air.foothill.initialHumidity,
          temperature: kGameConfiguration.air.foothill.initialTemperature,
        );

  @override
  void step() {
    Direction? direction = mountainward;
    if (direction == null) {
      // no mountain around: plain air that follows the wind of its neighbors
      _carryDust();
      _adaptWind();
      return;
    }

    // The foot of the mountain is a source: it sets its own wind and does not
    // adapt to the calm air around it.
    _changeUpdraft();
    setWind(direction, updraft);
    _carryDust();
  }

  void _changeUpdraft() {
    var foothill = kGameConfiguration.air.foothill;

    // run over: pick a new direction (up or down) and a new length
    if (_stepsLeft == 0) {
      _trend = gameModelRef.random.nextBool() ? 1 : -1;
      _stepsLeft = foothill.updraftRunMin +
          gameModelRef.random.nextInt(foothill.updraftRunMax - foothill.updraftRunMin + 1);
    }
    _stepsLeft--;

    double change = foothill.updraftChange * foothill.updraftMaxStrength;
    updraft = (updraft + _trend * change).clamp(0.0, foothill.updraftMaxStrength);
  }

  // The wind carries dust: this cell takes dust only from a neighbor whose
  // wind blows onto it (the neighbor's cell plus one step in its wind
  // direction is this cell). How much depends on the neighbor's wind
  // strength, not on who has more dust. What this cell gains, the neighbor
  // loses.
  void _carryDust() {
    double rate = kGameConfiguration.air.foothill.windTransfer;
    Layer airLayer = gameModelRef.getLayer(AirModel.staticLayerId);

    for (Direction direction in Direction.values) {
      AgentModel? neighbor = airLayer.get(cell + direction.step);
      if (neighbor is! AirModel) {
        continue;
      }

      // does the wind of the neighbor blow onto this cell?
      if (neighbor.cell + neighbor.windDirection.step == cell) {
        double share = min(1.0, neighbor.windStrength * rate);
        double transfer = neighbor.dust * share;
        neighbor.addDust(-transfer);
        addDust(transfer);
      }
    }
  }

  // The wind adapts to the wind around it: the average wind of all neighbors
  // (as vectors) pulls this cell's wind a part of the way towards it.
  void _adaptWind() {
    Layer airLayer = gameModelRef.getLayer(AirModel.staticLayerId);
    double sumX = 0;
    double sumY = 0;
    int count = 0;
    for (Direction direction in Direction.values) {
      AgentModel? neighbor = airLayer.get(cell + direction.step);
      if (neighbor is! AirModel) {
        continue;
      }
      sumX += neighbor.windX;
      sumY += neighbor.windY;
      count++;
    }
    if (count == 0) {
      return;
    }

    // the average wind around this cell
    double aroundX = sumX / count;
    double aroundY = sumY / count;

    // move this cell's wind a part of the way towards it
    double factor = kGameConfiguration.air.foothill.windAdaptation;
    double newX = windX + (aroundX - windX) * factor;
    double newY = windY + (aroundY - windY) * factor;

    windStrength = sqrt(newX * newX + newY * newY);
    if (windStrength > 0) {
      windDirection = Direction.closestTo(newX, newY);
    }
  }
}
