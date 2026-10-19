import 'package:echo_garden/representation/sound/engine/sound_backend.dart';
import 'package:echo_garden/representation/sound/engine/sound_spatializer.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Plays the sound space with SoLoud: per voice the volume, the pan, the play
/// speed (pitch) and a low-pass filter (dull from behind).
///
/// SoLoud has to be initialized before (see main).
class SoLoudSoundBackend implements SoundBackend {
  // every change is faded over this time, so a jump does not click
  static const Duration _fade = Duration(milliseconds: 60);

  final Map<int, ({AudioSource sound, SoundHandle handle})> _voices = {};
  int _nextVoice = 0;

  @override
  Future<int> startLoop(String asset) async {
    AudioSource sound = await SoLoud.instance.loadAsset(asset);
    // the filter has to be on before the sound is played
    sound.filters.biquadFilter.activate();
    SoundHandle handle = await SoLoud.instance.play(sound, volume: 0, looping: true);
    // 0.707 is a plain low-pass, without a boost at the cutoff
    sound.filters.biquadFilter.resonance(soundHandle: handle).value = 0.707;

    int voice = _nextVoice++;
    _voices[voice] = (sound: sound, handle: handle);
    return voice;
  }

  @override
  void setMix(int voice, SoundMix mix) {
    final playing = _voices[voice];
    if (playing == null) return;

    SoLoud.instance.fadeVolume(playing.handle, mix.volume, _fade);
    SoLoud.instance.fadePan(playing.handle, mix.pan, _fade);
    SoLoud.instance.fadeRelativePlaySpeed(playing.handle, mix.speed, _fade);
    playing.sound.filters.biquadFilter
        .frequency(soundHandle: playing.handle)
        .fadeFilterParameter(to: mix.cutoff, time: _fade);
  }

  @override
  void stop(int voice) {
    final playing = _voices.remove(voice);
    if (playing == null) return;
    SoLoud.instance.stop(playing.handle);
  }
}
