import 'package:echo_garden/input/input_device.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';

/// Moves the player with the arrow keys.
class KeyboardInputDevice extends InputDevice {
  KeyboardInputDevice(super.player) {
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
  }

  bool _onKeyEvent(KeyEvent event) {
    Set<LogicalKeyboardKey> pressed = HardwareKeyboard.instance.logicalKeysPressed;

    bool left = pressed.contains(LogicalKeyboardKey.arrowLeft);
    bool right = pressed.contains(LogicalKeyboardKey.arrowRight);
    bool up = pressed.contains(LogicalKeyboardKey.arrowUp);
    bool down = pressed.contains(LogicalKeyboardKey.arrowDown);

    double x = 0;
    if (left) x -= 1;
    if (right) x += 1;

    double y = 0;
    if (up) y -= 1;
    if (down) y += 1;

    player.direction = Vector2(x, y);

    // let other parts of the app see the key as well
    return false;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
  }
}
