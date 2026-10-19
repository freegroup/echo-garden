import 'package:echo_garden/representation/sound/engine/sound_backend.dart';
import 'package:echo_garden/representation/sound/engine/sound_source.dart';
import 'package:echo_garden/representation/sound/engine/sound_spatializer.dart';

/// Mixes the sound sources in space, as 3D audio engines do (Web Audio API,
/// OpenAL, SoLoud, FMOD), only in 2D.
///
/// It knows nothing about the world or the player: the listener is always at
/// the origin, and the soundlets place their sources relative to it (see
/// SoundSource). Every frame [update] computes for each source how it sounds
/// (see [spatialize]) and hands that to the backend.
class SoundManager {
  final SoundBackend backend;

  final Map<SoundSource, int> _voices = {};

  SoundManager({required this.backend});

  /// Adds a source and starts its loop; it stays silent until its volume is set.
  Future<void> add(SoundSource source) async {
    _voices[source] = await backend.startLoop(source.asset);
  }

  void remove(SoundSource source) {
    int? voice = _voices.remove(source);
    if (voice != null) backend.stop(voice);
  }

  void update() {
    for (MapEntry<SoundSource, int> entry in _voices.entries) {
      backend.setMix(entry.value, spatialize(entry.key));
    }
  }
}
