import 'package:echo_garden/representation/sound/engine/sound_backend.dart';
import 'package:echo_garden/representation/sound/engine/sound_listener.dart';
import 'package:echo_garden/representation/sound/engine/sound_source.dart';
import 'package:echo_garden/representation/sound/engine/sound_spatializer.dart';

/// The sound space: one listener and the sound sources around it, as in 3D
/// audio engines (Web Audio API, OpenAL, SoLoud, FMOD), only in 2D.
///
/// Every frame [update] computes for each source how it sounds for the
/// listener (see [spatialize]) and hands that to the backend. The owners of
/// the sources only move them and set their volume.
class SoundManager {
  final SoundBackend backend;
  final SoundListener listener;

  final Map<SoundSource, int> _voices = {};

  SoundManager({required this.backend, required this.listener});

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
      backend.setMix(entry.value, spatialize(listener, entry.key));
    }
  }
}
