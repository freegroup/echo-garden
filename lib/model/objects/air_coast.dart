import 'dart:math';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/direction.dart';
import 'package:echo_garden/model/layer.dart';
import 'package:echo_garden/model/objects/air.dart';

/// Air over a beach: the source of the breeze over the land.
///
/// The breeze does not jump. For a random number of steps it rises (or falls)
/// a little every step, then a new run with a new direction (up or down) and
/// a new length starts. So it changes smoothly instead of flickering.
class AirCoastModel extends AirModel {
  /// Where the land lies, as seen from this beach; null when there is none.
  /// Handed in by whoever creates the air (the terraformer knows the ground).
  final Direction? landward;

  /// The strength of the breeze this coast blows towards the land.
  double breeze = 0;

  int _trend = 1; // +1: the breeze rises, -1: it falls
  int _stepsLeft = 0; // steps left in the current run (incCount)

  AirCoastModel({required super.gameModelRef, required super.cell, required this.landward})
      : super(
          humidity: kGameConfiguration.air.coast.initialHumidity,
          temperature: kGameConfiguration.air.coast.initialTemperature,
        );

  @override
  void step() {
    Direction? direction = landward;
    if (direction == null) {
      // no land around: plain air that follows the wind of its neighbors
      _carryDust();
      _adaptWind();
      return;
    }

    // The coast is a source: it sets its own wind and does not adapt to the
    // calm air around it. The neighbors adapt to it, so the breeze moves
    // inland.
    _changeBreeze();
    setWind(direction, breeze);
    _carryDust();
  }

  void _changeBreeze() {
    var coast = kGameConfiguration.air.coast;

    // run over: pick a new direction (up or down) and a new length
    if (_stepsLeft == 0) {
      _trend = gameModelRef.random.nextBool() ? 1 : -1;
      _stepsLeft = coast.breezeRunMin +
          gameModelRef.random.nextInt(coast.breezeRunMax - coast.breezeRunMin + 1);
    }
    _stepsLeft--;

    double change = coast.breezeChange * coast.breezeMaxStrength;
    breeze = (breeze + _trend * change).clamp(0.0, coast.breezeMaxStrength);
  }

  // The wind carries dust: this cell takes dust only from a neighbor whose
  // wind blows onto it (the neighbor's cell plus one step in its wind
  // direction is this cell). How much depends on the neighbor's wind
  // strength, not on who has more dust. What this cell gains, the neighbor
  // loses.
  void _carryDust() {
    double rate = kGameConfiguration.air.coast.windTransfer;
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
    double factor = kGameConfiguration.air.coast.windAdaptation;
    double newX = windX + (aroundX - windX) * factor;
    double newY = windY + (aroundY - windY) * factor;

    windStrength = sqrt(newX * newX + newY * newY);
    if (windStrength > 0) {
      windDirection = Direction.closestTo(newX, newY);
    }
  }
}
