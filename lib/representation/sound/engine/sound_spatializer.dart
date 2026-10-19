import 'dart:math';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/representation/sound/engine/sound_source.dart';
import 'package:flame/components.dart';

/// How one source sounds for the listener right now.
class SoundMix {
  final double volume; // 0..1
  final double pan; // -1 left .. 1 right
  final double cutoff; // Hz of the low-pass filter: the lower, the duller
  final double speed; // play speed: below 1 lower, above 1 higher

  const SoundMix({
    required this.volume,
    required this.pan,
    required this.cutoff,
    required this.speed,
  });
}

/// Computes how a source sounds for the listener, which is at the origin and
/// faces north (see SoundSource). It follows the known pattern
/// of 3D audio engines (Web Audio API, OpenAL, SoLoud), in 2D:
/// - the volume falls off with the distance (see [distanceGain]),
/// - the pan comes from the direction: east is the right ear,
/// - behind the listener (south) the sound is duller and lower. Plain stereo
///   panning cannot tell front from back, so games use this as a hint, like
///   the head shadows sounds from behind,
/// - the Doppler effect raises what comes closer and lowers what goes away
///   (see [dopplerShift]).
SoundMix spatialize(SoundSource source) {
  final space = kGameConfiguration.sounds.space;

  // from the listener to the source, in cells; y grows to the south
  double dx = source.relativePosition.x;
  double dy = source.relativePosition.y;
  double distance = sqrt(dx * dx + dy * dy);

  // a source right at the listener is heard in front, with both ears
  double right = 0; // -1 west .. 1 east
  double behind = 0; // 0 in front or beside .. 1 straight south
  if (distance > 0) {
    right = dx / distance;
    behind = max(0.0, dy / distance);
  }

  // We hear pitches on a log scale, so the cutoff goes from front to rear by
  // a factor, not by a fixed amount of Hz.
  double cutoff = space.frontCutoff * pow(space.rearCutoff / space.frontCutoff, behind);

  double speed = (1 - behind * space.rearPitchDrop) * dopplerShift(source);

  return SoundMix(
    volume: source.volume * distanceGain(source, distance),
    pan: right,
    cutoff: cutoff,
    speed: speed,
  );
}

/// How loud a source still is at this distance (in cells), as in the Web Audio
/// API: up to refDistance it is at full volume; beyond maxDistance it gets no
/// quieter.
double distanceGain(SoundSource source, double distance) {
  double ref = source.refDistance;
  double far = source.maxDistance;
  double d = distance.clamp(ref, far);

  return switch (source.distanceModel) {
    DistanceModel.linear => (1 - source.rolloff * (d - ref) / (far - ref)).clamp(0.0, 1.0),
    DistanceModel.inverse => ref / (ref + source.rolloff * (d - ref)),
    DistanceModel.exponential => pow(d / ref, -source.rolloff).toDouble(),
  };
}

/// The Doppler effect: only the speed along the line between source and
/// listener counts. The source moves relative to the resting listener, as
/// in the classic formula c / (c - v). Returns the factor for the pitch: above
/// 1 when the source comes closer, below 1 when it moves away.
double dopplerShift(SoundSource source) {
  final space = kGameConfiguration.sounds.space;

  double distance = source.relativePosition.length;
  if (distance == 0) return 1;
  // from the source to the listener (at the origin)
  Vector2 towardsListener = -source.relativePosition / distance;

  // in cells per second, positive when the source comes closer
  double approaching = source.relativeVelocity.dot(towardsListener);

  // never close to the speed of sound, so the formula stays finite
  double limit = 0.9 * space.speedOfSound / space.dopplerFactor;
  approaching = min(approaching, limit);

  double c = space.speedOfSound;
  return c / (c - space.dopplerFactor * approaching);
}
