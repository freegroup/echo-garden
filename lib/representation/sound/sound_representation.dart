import 'package:echo_garden/representation/representation.dart';
import 'package:echo_garden/representation/sound/soundlets/soundlet.dart';
import 'package:echo_garden/representation/sound/soundlets/soundlet_forest.dart';
import 'package:echo_garden/representation/sound/soundlets/soundlet_ocean.dart';
import 'package:echo_garden/representation/sound/soundlets/soundlet_steps.dart';
import 'package:echo_garden/representation/sound/soundlets/soundlet_wind.dart';
import 'package:echo_garden/representation/sound/engine/sound_backend_soloud.dart';
import 'package:echo_garden/representation/sound/engine/sound_manager.dart';

/// Makes the world audible around the player.
///
/// Each type of sound is a soundlet with its own logic (see Soundlet); this
/// representation only holds them, drives them every frame and lets the
/// SoundManager mix their sources. The sounds are computed fresh every frame
/// from the world view, so no events are needed.
///
/// The steps already go through the SoundManager (sound in space). Sea, forest
/// and wind still use the older SoundEnvironment.
class SoundRepresentation extends Representation {
  late final List<Soundlet> soundlets;

  // made when the representation wakes up for the first time, because the
  // audio engine has to be ready by then
  SoundManager? _manager;

  SoundRepresentation(super.worldView, super.player) {
    soundlets = [
      SoundletOcean(worldView, player),
      SoundletForest(worldView, player),
      SoundletWind(worldView, player),
      SoundletSteps(worldView, player),
    ];
  }

  @override
  void wake() {
    super.wake();
    if (_manager == null) {
      SoundManager manager = SoundManager(backend: SoLoudSoundBackend());
      _manager = manager;
      for (Soundlet soundlet in soundlets) {
        soundlet.start(manager);
      }
    }
  }

  @override
  void syncAll() {
    // nothing to do: update() computes everything from the current world view
  }

  @override
  void sleep() {
    super.sleep();
    for (Soundlet soundlet in soundlets) {
      soundlet.sleep();
    }
    _manager?.update();
  }

  @override
  void update(double dt) {
    for (Soundlet soundlet in soundlets) {
      soundlet.update(dt);
    }
    _manager?.update();
  }
}
