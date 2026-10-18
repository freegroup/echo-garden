import 'dart:math';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/direction.dart';
import 'package:echo_garden/model/layer.dart';
import 'package:echo_garden/model/objects/air.dart';

/// Air over open water. The sea washes the fine dust out of the air: every
/// step the sea air loses half of its dust, then it takes dust from its
/// neighbors like any air.
class AirSeaModel extends AirModel {
  AirSeaModel({required super.gameModelRef, required super.cell})
      : super(
          humidity: kGameConfiguration.air.sea.initialHumidity,
          temperature: kGameConfiguration.air.sea.initialTemperature,
        );

  @override
  void step() {
    // the sea washes out half of the dust
    addDust(-dust / 2);
    _carryDust();
    _adaptWind();
  }

  // The wind carries dust: this cell takes dust only from a neighbor whose
  // wind blows onto it (the neighbor's cell plus one step in its wind
  // direction is this cell). How much depends on the neighbor's wind
  // strength, not on who has more dust. What this cell gains, the neighbor
  // loses.
  void _carryDust() {
    double rate = kGameConfiguration.air.sea.windTransfer;
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
    double factor = kGameConfiguration.air.sea.windAdaptation;
    double newX = windX + (aroundX - windX) * factor;
    double newY = windY + (aroundY - windY) * factor;

    windStrength = sqrt(newX * newX + newY * newY);
    if (windStrength > 0) {
      windDirection = Direction.closestTo(newX, newY);
    }
  }
}
