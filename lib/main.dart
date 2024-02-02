import 'package:echo_garden/scenario/configuration.dart';
import 'package:echo_garden/scenario/simulator.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  final game = EchoGardenSimulator(
    width: kConfiguration.world.width,
    height: kConfiguration.world.height,
  );
  runApp(GameWidget(game: game));
}
