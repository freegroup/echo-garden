import 'dart:math';

import 'package:echo_garden/input/input_device.dart';
import 'package:echo_garden/input/keyboard_input_device.dart';
import 'package:echo_garden/input/touch_input_device.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/player.dart';
import 'package:echo_garden/representation/graphics_representation.dart';
import 'package:echo_garden/representation/representation.dart';
import 'package:echo_garden/representation/sound_representation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Connects the model, the player, the input devices and the representations
/// and drives all of them once per frame.
///
/// The frame loop is independent of Flame, so the model and the sound keep
/// running even without graphics.
class GameSession {
  final GameModel model;
  late final Player player;
  final List<InputDevice> inputDevices = [];
  final List<Representation> representations = [];
  late final GraphicsRepresentation graphics;

  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // frame time not yet handed to the model, below one millisecond
  double _pendingMs = 0;

  // A frame longer than this (e.g. after the app was paused) is shortened,
  // so the player does not jump. Catching up comes with step 6.
  static const double _maxFrameTime = 0.1;

  GameSession(this.model) {
    player = Player.onLandNearBeach(model);

    inputDevices.add(KeyboardInputDevice(player));

    // the touch joystick is only needed on devices with a touch screen
    TouchInputDevice? touchInput;
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.macOS) {
      touchInput = TouchInputDevice(player);
      inputDevices.add(touchInput);
    }

    graphics = GraphicsRepresentation(model, player, touchInput: touchInput);
    representations.add(graphics);
    representations.add(SoundRepresentation(model, player));

    _ticker = Ticker(_onFrame);
  }

  void start() {
    for (Representation representation in representations) {
      representation.wake();
    }
    _lastElapsed = Duration.zero;
    _ticker.start();
  }

  void stop() {
    _ticker.stop();
    for (Representation representation in representations) {
      representation.sleep();
    }
  }

  void _onFrame(Duration elapsed) {
    double dt = (elapsed - _lastElapsed).inMicroseconds / Duration.microsecondsPerSecond;
    _lastElapsed = elapsed;
    dt = min(dt, _maxFrameTime);

    for (InputDevice inputDevice in inputDevices) {
      inputDevice.update();
    }

    player.update(dt);

    // the model counts in whole milliseconds; keep the rest for the next frame
    _pendingMs += dt * 1000;
    int ms = _pendingMs.floor();
    _pendingMs -= ms;
    model.advance(ms);

    for (Representation representation in representations) {
      if (representation.isAwake) {
        representation.update(dt);
      }
    }
  }
}
