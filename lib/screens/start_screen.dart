import 'package:echo_garden/model/game.dart';
import 'package:flutter/material.dart';
import 'package:echo_garden/session/game_session.dart';
import 'package:echo_garden/screens/game_screen.dart';

import '../utils/io.dart';
// Make sure to import your GameModel and loadGameModel function

class StartScreen extends StatefulWidget {
  final GameSession session;

  const StartScreen({Key? key, required this.session}) : super(key: key);

  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  String? errorMessage;

  Future<void> _loadGame(BuildContext context) async {
    try {
      // Attempt to load the game model here
      final GameModel? loadedGameModel = await loadGameModel();
      if (loadedGameModel != null && mounted) {
        // If loading succeeds, navigate to the game screen with the loaded game state
        widget.session.start();
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => GameScreen(session: widget.session),
        ));
      } else {
        // If no saved game is found, show an error message
        setState(() {
          errorMessage = "Kein gespeichertes Spiel gefunden.";
        });
      }
    } catch (e) {
      // Handle any errors during loading
      setState(() {
        errorMessage = "Das Spiel konnte nicht geladen werden: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Echo Garden'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (errorMessage != null) ...[
              Text(errorMessage!, style: TextStyle(color: Colors.red)),
              SizedBox(height: 20),
            ],
            ElevatedButton(
              onPressed: () {
                // Directly navigate to the game, starting a new game
                widget.session.start();
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => GameScreen(session: widget.session),
                ));
              },
              child: Text('Neues Spiel'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _loadGame(context),
              child: Text('Spiel laden'),
            ),
          ],
        ),
      ),
    );
  }
}
