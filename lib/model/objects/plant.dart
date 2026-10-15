import 'dart:math';

import 'package:echo_garden/model/agent.dart';
import 'package:echo_garden/model/cell.dart';
import 'package:echo_garden/model/game.dart';
import 'package:echo_garden/model/objects/seedable.dart';

abstract class PlantModel extends AgentModel {
  static String staticLayerId = "$PlantModel";

  PlantModel({required super.gameModelRef, required super.cell, super.energy});

  @override
  String get layerId => PlantModel.staticLayerId;

  /// True if a plant that gets along with the given types of ground can grow
  /// on the cell (see `growsOn` in the configuration).
  static bool growsAt(GameModel model, Cell cell, List<Type> growsOn) {
    return growsOn.contains(model.groundTypeAt(cell));
  }

  @override
  void step() {}

  bool grow(double growEnergy, double maxEnergy, double requiredMinWaterLevel) {
    if (energy >= maxEnergy) {
      return false;
    }
    // it is only possible to grow if the "soil" has enough water
    //
    AgentModel? soil = gameModelRef.getAgentAtCell(cell, SeedableModel.staticLayerId);
    if (soil is SeedableModel && soil.energy > requiredMinWaterLevel) {
      // soil has enough energy (water) for the tree...now we can grow
      //
      energy = min(maxEnergy, energy + growEnergy);

      // the soil looses the same amount of energy as the tree needs to grow
      //
      soil.energy -= growEnergy;

      // plant has grown up a little bit
      return true;
    }

    // no changes happens
    return false;
  }
}
