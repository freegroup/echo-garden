import 'package:echo_garden/sound/sound_spatializer.dart';

/// What the SoundManager needs from an audio engine.
///
/// The manager computes how every source sounds; the backend only plays it.
/// So the engine can be swapped, and tests can use a fake one.
abstract class SoundBackend {
  /// Starts [asset] as an endless loop, silent for now. Returns its voice.
  Future<int> startLoop(String asset);

  /// Sets how a voice sounds right now.
  void setMix(int voice, SoundMix mix);

  /// Stops a voice for good.
  void stop(int voice);
}
