import 'dart:math';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/input/input_device.dart';
import 'package:echo_garden/input/keyboard_input_device.dart';
import 'package:echo_garden/input/touch_input_device.dart';
import 'package:echo_garden/session/model_isolate.dart';
import 'package:echo_garden/session/player.dart';
import 'package:echo_garden/representation/graphics/graphics_representation.dart';
import 'package:echo_garden/representation/representation.dart';
import 'package:echo_garden/representation/sound/sound_representation.dart';
import 'package:echo_garden/representation/world_view.dart';
import 'package:flutter/scheduler.dart';

/// Connects the model, the player, the input devices and the representations
/// and drives the user interface once per frame.
///
/// The model runs in an isolate of its own (see ModelIsolate), in real time.
/// The readers (graphics, sound, the player) never touch it: they know the
/// world only from the world view, which the messages of the model build.
class GameSession {
  final ModelIsolate _modelIsolate;

  // what the user interface knows about the world, only from the messages
  WorldView get worldView => _modelIsolate.worldView;

  late final Player player;
  // the touch control; the start screen feeds it drag positions
  late final TouchInputDevice touchInput;
  final List<InputDevice> inputDevices = [];
  final List<Representation> representations = [];
  late final GraphicsRepresentation graphics;

  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // A frame longer than this (e.g. after the app was paused) is shortened,
  // so the player does not jump.
  static const double _maxFrameTime = 0.1;

  /// Starts the model in its own isolate and waits until the world is known.
  static Future<GameSession> create() async {
    ModelIsolate modelIsolate = await ModelIsolate.start(
      width: kGameConfiguration.grid.mapWidth,
      height: kGameConfiguration.grid.mapHeight,
    );
    return GameSession._(modelIsolate);
  }

  GameSession._(this._modelIsolate) {
    player = Player.onLandNearBeach(worldView);

    inputDevices.add(KeyboardInputDevice(player));

    // touch (finger on mobile, mouse drag on desktop) steers the player
    touchInput = TouchInputDevice(player);
    inputDevices.add(touchInput);

    graphics = GraphicsRepresentation(worldView, player);
    representations.add(graphics);
    representations.add(SoundRepresentation(worldView, player));

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

    for (Representation representation in representations) {
      if (representation.isAwake) {
        representation.update(dt);
      }
    }
  }
}
