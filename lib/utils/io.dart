import 'dart:convert';
import 'dart:io';
import 'package:echo_garden/model/game.dart';
import 'package:path_provider/path_provider.dart';

Future<void> saveGameModel(GameModel gameModel) async {
  final directory =
      await getApplicationDocumentsDirectory(); // Use path_provider to find the correct directory
  final file = File('${directory.path}/game_model.json'); // Define the file
  final jsonString = jsonEncode(gameModel.toJson()); // Convert GameModel instance to a JSON string
  await file.writeAsString(jsonString); // Write the JSON string to the file
}

Future<GameModel?> loadGameModel() async {
  try {
    final directory =
        await getApplicationDocumentsDirectory(); // Use path_provider to find the directory
    final file = File('${directory.path}/game_model.json'); // Define the file
    final jsonString = await file.readAsString(); // Read the JSON string from the file
    final jsonMap =
        jsonDecode(jsonString) as Map<String, dynamic>; // Parse the JSON string into a Map
    return GameModel.fromJson(jsonMap); // Convert the Map into a GameModel instance
  } catch (e) {
    print("Failed to load game model: $e");
    return null; // Return null in case of failure
  }
}
