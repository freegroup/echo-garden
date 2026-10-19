import 'package:echo_garden/representation/sound/engine/sound_manager.dart';
import 'package:echo_garden/representation/world_view.dart';
import 'package:echo_garden/session/player.dart';

/// A soundlet: one type of sound of the world, with its own logic: wind, sea, forest,
/// steps, ...
///
/// A soundlet looks at the world view around the player, decides what is heard
/// and where, and hands that as sources, placed relative to the player, to the
/// SoundManager. The manager only mixes them; gathering and merging (e.g. many
/// birds into a few sources) is the soundlet's task.
abstract class Soundlet {
  final WorldView worldView;
  final Player player;

  Soundlet(this.worldView, this.player);

  /// Called once, when the audio engine is ready: e.g. adds the sources.
  Future<void> start(SoundManager manager) async {}

  /// Called every frame while the sound is awake.
  void update(double dt);

  /// Makes the sound silent, e.g. while the app is in the background.
  void sleep() {}

  // ---- tools ----

  /// Sounds of the surroundings are heard up to this distance, in cells.
  static const int hearingRadius = 7;
}
