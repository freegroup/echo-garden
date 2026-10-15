import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/objects/beach.dart';
import 'package:echo_garden/player.dart';
import 'package:echo_garden/strategy/base.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the player walks in the direction the input device set', () {
    final player = Player(position: Vector2(10, 10));

    player.direction = Vector2(1, 0);
    player.update(1.0);

    expect(player.position.x, closeTo(10 + kGameConfiguration.player.speed, 0.0001));
    expect(player.position.y, 10);
  });

  test('the player starts on land near a beach', () {
    final model = GameModel(
        size: Vector2(kGameConfiguration.tileMap.width, kGameConfiguration.tileMap.height));

    final player = Player.onLandNearBeach(model);
    final cell = player.position.clone()..floor();

    expect(model.getAgentAtCell(cell, SeedableModel.staticLayerId), isNotNull,
        reason: 'the start cell must be land');
    final beach = MovementStrategy(model: model).getNearestCellForAgentTypeOnLayer(
      cell: cell,
      radius: kGameConfiguration.player.startBeachDistance,
      type: BeachModel,
      layerId: PatchModel.staticLayerId,
    );
    expect(beach, isNotNull, reason: 'a beach must be close by');
  });

  test('a player without direction stands still', () {
    final player = Player(position: Vector2(10, 10));

    player.update(1.0);

    expect(player.position, Vector2(10, 10));
  });
}
