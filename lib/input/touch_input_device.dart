import 'package:echo_garden/input/input_device.dart';
import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';

/// Moves the player with an on-screen joystick.
///
/// The joystick itself has to be shown on the screen, so the graphics
/// representation adds [joystick] to its viewport.
class TouchInputDevice extends InputDevice {
  late final JoystickComponent joystick;
  bool _wasTouched = false;

  TouchInputDevice(super.player) {
    final knobPaint = BasicPalette.darkGreen.withAlpha(100).paint();
    final backgroundPaint = BasicPalette.green.withAlpha(30).paint();
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 30, paint: knobPaint),
      background: CircleComponent(radius: 100, paint: backgroundPaint),
      margin: const EdgeInsets.only(right: 40, bottom: 40),
    );
  }

  @override
  void update() {
    bool isTouched = !joystick.relativeDelta.isZero();

    // Only write the direction while the joystick is used or right after it
    // was released. Otherwise it would overwrite the keyboard every frame.
    if (isTouched || _wasTouched) {
      player.direction = joystick.relativeDelta.clone();
    }
    _wasTouched = isTouched;
  }
}
