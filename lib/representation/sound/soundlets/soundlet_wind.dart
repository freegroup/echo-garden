import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/representation/sound/soundlets/soundlet.dart';
import 'package:echo_garden/representation/sound/sound_env.dart';

/// The wind: the stronger the wind around the player, the louder. The wind of
/// the player's cell and its neighbors is averaged, so the sound does not jump
/// when the player crosses into the next cell.
class SoundletWind extends Soundlet {
  SoundletWind(super.worldView, super.player);

  @override
  void update(double dt) {
    Cell listenerCell = player.position.cell;
    int radius = kGameConfiguration.sounds.wind.radius;
    double sum = 0;
    int count = 0;
    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        var wind = worldView.windAt(Cell(listenerCell.x + dx, listenerCell.y + dy));
        if (wind != null) {
          sum += wind.strength;
          count++;
        }
      }
    }
    if (count == 0) {
      SoundEnvironment.stop(Sound.wind);
      return;
    }

    double averageWind = sum / count;
    double volume = (averageWind / kGameConfiguration.sounds.wind.fullStrength).clamp(0.0, 1.0) *
        kGameConfiguration.sounds.wind.volume;
    if (volume <= 0) {
      SoundEnvironment.stop(Sound.wind);
      return;
    }
    SoundEnvironment.loop(Sound.wind, volume);
  }

  @override
  void sleep() {
    SoundEnvironment.stop(Sound.wind);
  }
}
