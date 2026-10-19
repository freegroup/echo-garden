import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/representation/sound/soundlets/soundlet.dart';
import 'package:echo_garden/representation/sound/sound_env.dart';

/// The forest: the more energy the trees (oaks, firs and pines) around the
/// player have, the louder, up to its volume in a dense forest.
class SoundletForest extends Soundlet {
  // below this energy around the player there is no forest to hear
  static const double _minEnergy = 200;

  SoundletForest(super.worldView, super.player);

  @override
  void update(double dt) {
    Cell listenerCell = player.position.cell;
    double energy = 0;
    for (Type tree in [TreeModel, FirModel, PineModel]) {
      energy += worldView.energyAround(
        cell: listenerCell,
        type: tree,
        radius: Soundlet.hearingRadius,
        layerId: PlantModel.staticLayerId,
      );
    }
    if (energy <= _minEnergy) {
      SoundEnvironment.stop(Sound.blackForest);
      return;
    }

    // as loud as it gets: every cell around full of fully grown oaks
    double maxEnergy = kGameConfiguration.plant.tree.maxEnergy *
        (Soundlet.hearingRadius * Soundlet.hearingRadius - 1);
    energy = energy.clamp(_minEnergy, maxEnergy);
    double volume =
        (energy - _minEnergy) / (maxEnergy - _minEnergy) * kGameConfiguration.sounds.forest.volume;
    SoundEnvironment.loop(Sound.blackForest, volume);
  }

  @override
  void sleep() {
    SoundEnvironment.stop(Sound.blackForest);
  }
}
