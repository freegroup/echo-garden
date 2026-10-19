import 'package:echo_garden/session/player.dart';

/// Base class for everything that lets the player control the game:
/// keyboard, touch joystick, later e.g. gestures on a watch.
///
/// An input device never changes the representations, it only tells the
/// player where to go.
abstract class InputDevice {
  final Player player;

  InputDevice(this.player);

  /// Called every frame. Devices that have to be polled read their state here.
  void update() {}

  void dispose() {}
}
