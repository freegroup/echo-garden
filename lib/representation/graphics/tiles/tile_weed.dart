import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/representation/graphics/tiles/tile_plant.dart';

/// Weed: always the same image.
class TileWeed extends TilePlant {
  TileWeed() : super(type: WeedModel, imageNames: ['weed-07.png']);
}
