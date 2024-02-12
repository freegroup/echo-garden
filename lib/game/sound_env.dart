import 'package:flame_audio/flame_audio.dart';

enum Sound {
  ocean,
  campfire,
  blackForest,
}

final Map<Sound, String> _soundFiles = {
  Sound.ocean: "bg-ocean.mp3",
  Sound.campfire: "bg-campfire.mp3",
  Sound.blackForest: "bg-forest-black.mp3",
};

final Map<Sound, Future<AudioPlayer>> _audioPlayers = {};

class SoundEnvironment {
  static Future<void> init() async {}

  static Future<void> play(Sound sound, double volume) async {
    var player = await _audioPlayers[sound];

    if (player != null) {
      await player.setVolume(volume);
      await player.stop();
      await player.resume();
    } else {
      var file = _soundFiles[sound];
      if (file != null) {
        var newPlayer = FlameAudio.play(file, volume: volume);
        _audioPlayers[sound] = newPlayer;
      }
    }
  }

  static Future<void> loop(Sound sound, double volume) async {
    try {
      volume = volume / 3;
      Future<AudioPlayer>? player = _audioPlayers[sound];
      if (player != null) {
        (await player).setVolume(volume);
        //await player.setBalance(-1);
      } else {
        var file = _soundFiles[sound];
        if (file != null) {
          _audioPlayers[sound] = FlameAudio.loop(file, volume: volume);
        }
      }
    } on Exception catch (e) {
      print(e);
    }
  }

  static Future<void> stop(Sound sound) async {
    Future<AudioPlayer>? player = _audioPlayers.remove(sound);
    if (player != null) {
      AudioPlayer p = await player;
      p.stop();
      p.dispose();
    }
  }
}
