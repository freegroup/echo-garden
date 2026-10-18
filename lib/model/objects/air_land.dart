import 'dart:math';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/direction.dart';
import 'package:echo_garden/model/layer.dart';
import 'package:echo_garden/model/objects/air.dart';

/// Air over flat land. The land makes no wind, it only lets wind through:
/// normally it slows the wind down a little, but now and then a cell lets the
/// wind pass without slowing it for a while (see [nopCount]).
class AirLandModel extends AirModel {
  /// Steps left in which this cell does not slow the wind down.
  int nopCount = 0;

  AirLandModel({required super.gameModelRef, required super.cell})
      : super(
          humidity: kGameConfiguration.air.land.initialHumidity,
          temperature: kGameConfiguration.air.land.initialTemperature,
        );

  @override
  void step() {
    _carryDust();
    _adaptWind();
    _slowDownWind();
  }

  void _slowDownWind() {
    var land = kGameConfiguration.air.land;

    if (nopCount != 0) {
      // let the wind pass: no slowing down
    } else {
      windStrength *= land.windDamping;
    }

    if (nopCount > 0) {
      nopCount--;
    }

    // not letting the wind pass right now: maybe start doing so for a while
    if (nopCount == 0 && gameModelRef.random.nextDouble() < land.gustChance) {
      nopCount = gameModelRef.random.nextInt(land.gustMaxSteps + 1);
    }
  }

  // The wind carries dust: this cell takes dust only from a neighbor whose
  // wind blows onto it (the neighbor's cell plus one step in its wind
  // direction is this cell). How much depends on the neighbor's wind
  // strength, not on who has more dust. What this cell gains, the neighbor
  // loses.
  void _carryDust() {
    double rate = kGameConfiguration.air.land.windTransfer;
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
    double factor = kGameConfiguration.air.land.windAdaptation;
    double newX = windX + (aroundX - windX) * factor;
    double newY = windY + (aroundY - windY) * factor;

    windStrength = sqrt(newX * newX + newY * newY);
    if (windStrength > 0) {
      windDirection = Direction.closestTo(newX, newY);
    }
  }
}
