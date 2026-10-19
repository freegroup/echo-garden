import 'package:echo_garden/model/pos.dart';
import 'package:flame/components.dart';

/// The one who hears: where it is and how it moves.
///
/// It always faces north (up on the map), like a map that does not turn: east
/// is the right ear, west the left ear, south is behind.
class SoundListener {
  Pos position;

  // units per second, for the Doppler effect
  Vector2 velocity = Vector2.zero();

  SoundListener({required this.position});
}
