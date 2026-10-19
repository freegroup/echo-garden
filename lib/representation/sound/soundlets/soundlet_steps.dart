import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/representation/sound/soundlets/soundlet.dart';
import 'package:echo_garden/representation/sound/engine/sound_manager.dart';
import 'package:echo_garden/representation/sound/engine/sound_source.dart';
import 'package:flame/components.dart';

/// The steps of the player: heard while the player really moves (not when it
/// walks against the coast), a little ahead in the walking direction. So they
/// come from where the player goes: from the left when it goes left, dull from
/// behind when it goes south.
class SoundletSteps extends Soundlet {
  final SoundSource _steps = SoundSource(asset: 'assets/audio/steps-grass.mp3');

  // where the player was in the last frame, to hear whether it really moves
  late Pos _lastPlayerPosition;

  SoundletSteps(super.worldView, super.player) {
    _lastPlayerPosition = player.position;
  }

  @override
  Future<void> start(SoundManager manager) async {
    await manager.add(_steps);
  }

  @override
  void update(double dt) {
    Pos moved = player.position - _lastPlayerPosition;
    _lastPlayerPosition = player.position;

    if (moved.x == 0 && moved.y == 0) {
      _steps.volume = 0;
      return;
    }

    // relative to the listener: a little ahead in the walking direction, and
    // going along with it (no Doppler effect)
    Vector2 direction = Vector2(moved.x.toDouble(), moved.y.toDouble()).normalized();
    _steps.relativePosition = direction * kGameConfiguration.sounds.steps.ahead;
    _steps.relativeVelocity = Vector2.zero();
    _steps.volume = kGameConfiguration.sounds.steps.volume;
  }

  @override
  void sleep() {
    _steps.volume = 0;
  }
}
