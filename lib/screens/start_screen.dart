import 'package:echo_garden/model/game.dart';
import 'package:flutter/material.dart';
import 'package:echo_garden/game/game.dart';
import 'package:flame/game.dart';

import '../utils/io.dart';
// Make sure to import your GameModel and loadGameModel function

class StartScreen extends StatefulWidget {
  final GameVisualization game;

  const StartScreen({Key? key, required this.game}) : super(key: key);

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
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) =>
              GameWidget(game: widget.game), // Adjust if you need to pass the loaded game model
        ));
      } else {
        // If no saved game is found, show an error message
        setState(() {
          errorMessage = "No saved game found.";
        });
      }
    } catch (e) {
      // Handle any errors during loading
      setState(() {
        errorMessage = "Failed to load the game: $e";
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
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => GameWidget(game: widget.game),
                ));
              },
              child: Text('New Game'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _loadGame(context),
              child: Text('Load Game'),
            ),
          ],
        ),
      ),
    );
  }
}
