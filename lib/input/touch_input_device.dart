import 'dart:ui';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/input/input_device.dart';
import 'package:flame/components.dart';

/// Moves the player by touch, like an IBM TrackPoint: the finger offset from
/// where it first touched is the walk vector — direction and speed. Hold a
/// direction and the player keeps walking; pull further to go faster; release
/// to stop. There is no visible knob, and the touch may start anywhere.
///
/// The game screen feeds the positions in: from a GestureDetector (finger or
/// mouse drag), and on Android with TalkBack on from its touch exploration.
class TouchInputDevice extends InputDevice {
  Offset? _origin; // where the finger first touched

  TouchInputDevice(super.player);

  void dragStart(Offset position) {
    _origin = position;
  }

  void dragUpdate(Offset position) {
    final origin = _origin;
    if (origin == null) return;

    final offset = position - origin;
    final distance = offset.distance;
    final deadZone = kGameConfiguration.player.touchDeadZone;
    if (distance < deadZone) {
      player.direction = Vector2.zero();
      return;
    }

    // speed grows from the dead zone up to touchFullSpeed, as a factor 0..1
    final fullSpeed = kGameConfiguration.player.touchFullSpeed;
    final magnitude = ((distance - deadZone) / (fullSpeed - deadZone)).clamp(0.0, 1.0);
    player.direction = Vector2(offset.dx, offset.dy) / distance * magnitude;
  }

  void dragEnd() {
    _origin = null;
    player.direction = Vector2.zero();
  }
}
