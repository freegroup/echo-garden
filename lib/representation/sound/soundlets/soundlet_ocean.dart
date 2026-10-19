import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/objects/beach.dart';
import 'package:echo_garden/representation/sound/soundlets/soundlet.dart';
import 'package:echo_garden/representation/sound/sound_env.dart';

/// The sea: the nearer the closest beach, the louder, up to its volume right
/// at the beach.
class SoundletOcean extends Soundlet {
  SoundletOcean(super.worldView, super.player);

  @override
  void update(double dt) {
    Pos listener = player.position;
    Cell? nearestBeach = worldView.nearestCellOf(
      cell: listener.cell,
      type: BeachModel,
      radius: Soundlet.hearingRadius,
      layerId: PatchModel.staticLayerId,
    );
    if (nearestBeach == null) {
      SoundEnvironment.stop(Sound.ocean);
      return;
    }

    double distanceInCells =
        nearestBeach.center.distanceTo(listener) / kGameConfiguration.grid.gridWidth;
    double distance = distanceInCells.clamp(0, Soundlet.hearingRadius.toDouble());
    double volume =
        (1 - (distance / Soundlet.hearingRadius)) * kGameConfiguration.sounds.ocean.volume;
    SoundEnvironment.loop(Sound.ocean, volume);
  }

  @override
  void sleep() {
    SoundEnvironment.stop(Sound.ocean);
  }
}
