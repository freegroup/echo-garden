import 'dart:math';

import 'package:echo_garden/scenario/configuration.dart';
import 'package:echo_garden/scenario/patch.dart';

class TreePatch extends Patch {
  TreePatch({required super.scheduler, super.x, super.y, super.cell}) {
    paint.color = kConfiguration.plant.tree.color;
    energy = kConfiguration.plant.tree.initialEnergy;
  }

  @override
  void step() {
    energy = min(kConfiguration.plant.tree.maxEnergy, energy + kConfiguration.plant.tree.growEnergy);

    // Convert energy range from 0-maxEnergy to 0.0-1.0 for opacity
    double opacity = energy / kConfiguration.plant.tree.maxEnergy;

    paint.color = kConfiguration.plant.tree.color.withOpacity(opacity);
  }
}
