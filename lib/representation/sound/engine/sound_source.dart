import 'package:flame/components.dart';

/// How a sound gets quieter with the distance. The formulas are the ones of the
/// Web Audio API (see distanceGain).
enum DistanceModel { linear, inverse, exponential }

/// A looping sound, placed relative to the listener.
///
/// The listener is always at the origin and faces north: x grows to the right
/// ear, y grows to the back (south). The owner (a soundlet, which knows the
/// player and the world) sets where the source is and how loud it is; the
/// SoundManager makes it sound right (distance, ear, dull from behind, Doppler).
class SoundSource {
  // the sound file, e.g. 'assets/audio/steps-grass.mp3'
  final String asset;

  // in cells, relative to the listener
  Vector2 relativePosition = Vector2.zero();

  // in cells per second, relative to the listener, for the Doppler effect;
  // zero for a source that goes along with the listener
  Vector2 relativeVelocity = Vector2.zero();

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
    this.distanceModel = DistanceModel.inverse,
    this.refDistance = 1,
    this.maxDistance = 20,
    this.rolloff = 1,
  });
}
