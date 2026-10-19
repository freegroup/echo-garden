import 'dart:async';

import 'package:echo_garden/game_session.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// The playing screen: the game full-screen with the touch control over it,
/// plus a menu.
///
/// Two modes:
/// - closed: a drag anywhere steers the player (TrackPoint style).
/// - open: the walking pauses and the menu takes the gestures.
/// A long press opens and closes the menu.
///
/// The menu works in two ways, depending on whether a screen reader runs:
/// - without: the app speaks itself (TTS); swipe up/down moves through the
///   entries, double-tap chooses.
/// - with TalkBack: the entries are accessible buttons, so TalkBack moves
///   through them with its own swipes and reads them; double-tap chooses.
///   Messages go through TalkBack too (a live region), so only one voice
///   speaks.
/// The visible list is only for sighted debugging.
///
/// With TalkBack on (Android), a finger arrives as hover events instead of a
/// drag. The MainActivity sends them over the channel "echo_garden/explore_touch",
/// and they steer the player the same way, so one finger works there too.
class GameScreen extends StatefulWidget {
  final GameSession session;

  const GameScreen({super.key, required this.session});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final FlutterTts _tts = FlutterTts();

  // the finger moves of TalkBack's touch exploration, sent by the MainActivity
  static const EventChannel _exploreTouch = EventChannel('echo_garden/explore_touch');
  StreamSubscription<dynamic>? _exploreTouchSubscription;

  // a swipe faster than this (pixels/second) moves the menu selection
  static const double _swipeVelocity = 300;

  // ghost entries for now: they only speak, they do nothing yet
  final List<String> _items = ['Platzhalter eins', 'Platzhalter zwei', 'Platzhalter drei'];

  // the last entry of the menu closes it
  static const String _closeEntry = 'Menü schließen';

  bool _menuOpen = false;
  int _selected = 0;

  // whether a screen reader (TalkBack) runs; read from the MediaQuery in build
  bool _screenReader = false;

  // the last message for the screen reader; it reads it when it changes
  String _status = '';

  List<String> get _entries => [..._items, _closeEntry];

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('de-DE');
    // only the Android app sends these events
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _exploreTouchSubscription = _exploreTouch.receiveBroadcastStream().listen(_onExploreTouch);
    }
  }

  @override
  void dispose() {
    _exploreTouchSubscription?.cancel();
    super.dispose();
  }

  // A finger moved with TalkBack on: steer like a drag (only while walking).
  void _onExploreTouch(dynamic event) {
    if (_menuOpen) return;
    final map = event as Map;
    final position = Offset((map['x'] as num).toDouble(), (map['y'] as num).toDouble());
    final touch = widget.session.touchInput;
    switch (map['kind']) {
      case 'start':
        touch.dragStart(position);
      case 'move':
        touch.dragUpdate(position);
      case 'end':
        touch.dragEnd();
    }
  }

  // ---- speaking ----

  // Says a message: with a screen reader through it, otherwise with our own voice.
  void _say(String text) {
    if (_screenReader) {
      setState(() => _status = text);
    } else {
      _speak(text);
    }
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  // ---- the menu ----

  void _openMenu() {
    // stop walking while the menu is open
    widget.session.touchInput.dragEnd();
    setState(() {
      _menuOpen = true;
      _selected = 0;
    });
    // a screen reader announces the menu by itself (see _menuOverlay)
    if (!_screenReader) {
      _say('Menü. ${_entries[_selected]}');
    }
  }

  void _closeMenu() {
    setState(() => _menuOpen = false);
    _say('Menü geschlossen');
  }

  void _moveSelection(int delta) {
    setState(() {
      _selected = (_selected + delta) % _entries.length;
      if (_selected < 0) _selected += _entries.length;
    });
    _say(_entries[_selected]);
  }

  void _choose(int index) {
    if (_entries[index] == _closeEntry) {
      _closeMenu();
      return;
    }
    setState(() => _selected = index);
    // ghost: the entries do nothing yet
    _say('gewählt: ${_entries[index]}');
  }

  // ---- gestures ----

  void _onLongPress() {
    if (_menuOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _onPanStart(DragStartDetails d) {
    if (!_menuOpen) widget.session.touchInput.dragStart(d.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!_menuOpen) widget.session.touchInput.dragUpdate(d.localPosition);
  }

  void _onPanEnd(DragEndDetails d) {
    if (!_menuOpen) {
      widget.session.touchInput.dragEnd();
      return;
    }
    // in the menu a swipe up/down changes the selection
    final vy = d.velocity.pixelsPerSecond.dy;
    if (vy < -_swipeVelocity) {
      _moveSelection(-1);
    } else if (vy > _swipeVelocity) {
      _moveSelection(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    _screenReader = MediaQuery.accessibleNavigationOf(context);

    return PopScope(
      // the back gesture closes the menu instead of leaving the game
      canPop: !_menuOpen,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && _menuOpen) _closeMenu();
      },
      child: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: _onLongPress,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onDoubleTap: _menuOpen ? () => _choose(_selected) : null,
          child: Stack(
            children: [
              // while the menu is open the screen reader only sees the menu
              ExcludeSemantics(
                excluding: _menuOpen,
                child: GameWidget(game: widget.session.graphics.game),
              ),
              if (_menuOpen) _menuOverlay(),
              if (_screenReader) _statusLine(),
            ],
          ),
        ),
      ),
    );
  }

  // Like a dialog: a route of its own with a name, so TalkBack announces
  // "Menü" when it opens and only moves through its entries.
  Widget _menuOverlay() {
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Menü',
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < _entries.length; i++) _menuEntry(i),
          ],
        ),
      ),
    );
  }

  // One entry: for TalkBack a button with its name, double-tap chooses it.
  // When TalkBack moves to it, it is also highlighted on the screen.
  Widget _menuEntry(int index) {
    bool isSelected = index == _selected;
    return Semantics(
      button: true,
      label: _entries[index],
      onTap: () => _choose(index),
      onDidGainAccessibilityFocus: () => setState(() => _selected = index),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          _entries[index],
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontSize: isSelected ? 36 : 28,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // The messages for the screen reader: it reads this line whenever it changes.
  Widget _statusLine() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 8,
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Text(
          _status,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
  }
}
