import 'package:echo_garden/model/pos.dart';
import 'package:flame/components.dart';

/// How a sound gets quieter with the distance. The formulas are the ones of the
/// Web Audio API (see distanceGain).
enum DistanceModel { linear, inverse, exponential }

/// A sound in the world: a looping sound at a position.
///
/// The owner moves it and sets its volume; the SoundManager makes it sound
/// right for the listener (distance, direction, Doppler effect).
class SoundSource {
  // the sound file, e.g. 'assets/audio/steps-grass.mp3'
  final String asset;

  Pos position;

  // units per second, for the Doppler effect
  Vector2 velocity = Vector2.zero();

  // 0..1, set by the owner; 0 is silent
  double volume = 0;

  final DistanceModel distanceModel;

  // in cells: up to this distance the sound is at full volume
  final double refDistance;

  // in cells: beyond this distance the sound gets no quieter (linear: silent)
  final double maxDistance;

  // how fast the sound gets quieter with the distance
  final double rolloff;

  SoundSource({
    required this.asset,
    required this.position,
    this.distanceModel = DistanceModel.inverse,
    this.refDistance = 1,
    this.maxDistance = 20,
    this.rolloff = 1,
  });
}
