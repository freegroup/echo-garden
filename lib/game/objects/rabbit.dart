import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/objects/tile.dart';
import 'package:echo_garden/model/actors/rabbit.dart';
import 'package:flame/components.dart';

class RabbitTile extends TileSquare {
  RabbitTile({required super.agentModel, required Vector2 position})
      : super(position: position, spriteFilenames: ["rabbit-01.png"]);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void onModelChange() {
    print("rabbit changed....");
    var model = agentModel as RabbitAgent;
    position = model.cell * kGameConfiguration.world.tileSize;
  }
}
