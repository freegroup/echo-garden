import 'dart:math';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/objects/seedable.dart';

class SoilModel extends SeedableModel {
  SoilModel({required super.gameModelRef, required super.cell, super.energy}) {
    energy = kGameConfiguration.patch.soil.initialEnergy;
  }

  @override
  void step() {
    energy = min(
      kGameConfiguration.patch.soil.maxEnergy,
      energy + kGameConfiguration.patch.soil.incEnergy,
    );
  }
}
