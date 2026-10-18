import 'dart:collection';
import 'dart:math';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/movement_mode.dart';
import 'package:echo_garden/model/objects/beach.dart';
import 'package:echo_garden/model/objects/flat_water.dart';
import 'package:echo_garden/model/terraformer/diamond_square.dart';
import 'package:echo_garden/strategy/base.dart';

/// Shapes the landscape of a new map: water and soil, beach, flat water,
/// mountains on land and rocky islands in the water.
///
/// The heights come from [diamondSquare]; this class decides what the
/// heights mean. All land the player can walk on is connected: small pieces
/// of land become water, bigger ones get a land bridge.
///
/// The same seed always gives the same landscape.
class Terraformer {
  final GameModel model;
  final Random _random;

  Terraformer(this.model, {int? seed}) : _random = Random(seed);

  void shape() {
    var heightMap = diamondSquare(model.width, model.height, _random);

    // All heights of the map, sorted. The height map is bigger than the map
    // (its size must be 2^n + 1), so only the part that is used counts.
    List<double> sortedHeights = [];
    for (int x = 0; x < model.width; x++) {
      for (int y = 0; y < model.height; y++) {
        sortedHeights.add(heightMap[x][y]);
      }
    }
    sortedHeights.sort();

    // the lowest part of the map becomes water
    int waterIndex =
        (sortedHeights.length * (kGameConfiguration.world.waterPercentage / 100.0)).floor();
    double waterThreshold = sortedHeights[waterIndex];
    for (int x = 0; x < model.width; x++) {
      for (int y = 0; y < model.height; y++) {
        if (heightMap[x][y] < waterThreshold) {
          model.add(WaterModel(gameModelRef: model, cell: Cell(x, y)));
        } else {
          model.add(SoilModel(gameModelRef: model, cell: Cell(x, y)));
        }
      }
    }

    // one connected land: small pieces become water, bigger ones get a bridge
    _floodSmallIslands();
    _connectRegions(_isSoil, _buildLandBridge);

    // place beach tiles near to the water.
    // this means convert "seedable" to "beach"
    //
    var placeChecker = MovementStrategy(model: model);
    for (int x = 0; x < model.width; x++) {
      for (int y = 0; y < model.height; y++) {
        Cell cell = Cell(x, y);
        AgentModel? seedable = model.getAgentAtCell(cell, SeedableModel.staticLayerId);
        // check of around of the seedable is water => convert to beach
        if (seedable != null) {
          if (placeChecker.isAgentTypeNeighborOnLayer(
              cell: cell, layerId: PatchModel.staticLayerId, type: WaterModel)) {
            model.remove(seedable);
            model.add(BeachModel(gameModelRef: model, cell: cell));
          }
        }
      }
    }

    // place flat-water tiles near to the beach.
    // this means convert "seedable" to "beach"
    //
    for (int x = 0; x < model.width; x++) {
      for (int y = 0; y < model.height; y++) {
        Cell cell = Cell(x, y);
        AgentModel? water = model.getAgentAtCell(cell, PatchModel.staticLayerId);
        // check of around of the seedable is water => convert to beach
        if (water is WaterModel) {
          if (placeChecker.isAgentTypeNeighborOnLayer(
              cell: cell, layerId: PatchModel.staticLayerId, type: BeachModel)) {
            model.remove(water);
            model.add(FlatWaterModel(gameModelRef: model, cell: cell));
          }
        }
      }
    }

    // place flat-water tiles near to the beach.
    // this means convert "seedable" to "beach"
    //
    for (int x = 0; x < model.width; x++) {
      for (int y = 0; y < model.height; y++) {
        Cell cell = Cell(x, y);
        AgentModel? flatWater = model.getAgentAtCell(cell, PatchModel.staticLayerId);
        // check of around of the seedable is water => convert to beach
        if (flatWater is FlatWaterModel) {
          var neighbours = placeChecker.getNeighborhoodByType(
              cell: cell, layerId: PatchModel.staticLayerId, type: BeachModel);
          if (neighbours.length > 5) {
            model.remove(flatWater);
            model.add(BeachModel(gameModelRef: model, cell: cell));
          }
        }
      }
    }
    for (int x = 0; x < model.width; x++) {
      for (int y = 0; y < model.height; y++) {
        Cell cell = Cell(x, y);
        AgentModel? beach = model.getAgentAtCell(cell, PatchModel.staticLayerId);
        // check of around of the seedable is water => convert to beach
        if (beach is BeachModel) {
          var neighbours = placeChecker.getNeighborhoodByType(
              cell: cell, layerId: PatchModel.staticLayerId, type: FlatWaterModel);
          if (neighbours.length > 5) {
            model.remove(beach);
            model.add(FlatWaterModel(gameModelRef: model, cell: cell));
          }
        }
      }
    }
    for (int x = 0; x < model.width; x++) {
      for (int y = 0; y < model.height; y++) {
        Cell cell = Cell(x, y);
        AgentModel? water = model.getAgentAtCell(cell, PatchModel.staticLayerId);
        // check of around of the seedable is water => convert to beach
        if (water is WaterModel) {
          var neighbours = placeChecker.getNeighborhoodByType(
              cell: cell, layerId: PatchModel.staticLayerId, type: FlatWaterModel);
          if (neighbours.length > 6) {
            model.remove(water);
            model.add(FlatWaterModel(gameModelRef: model, cell: cell));
          }
        }
      }
    }

    _placeMountainsOnLand(heightMap, sortedHeights);
    _placeRockyIslands();

    // Last check: the beaches or the mountains may have cut something off
    // again, e.g. a valley behind high peaks.
    _connectRegions(_isWalkableLand, _buildWalkablePassage);

    // the landscape is final now: the air above it can be placed
    _placeAir();
  }

  // ---- the air ----

  // Air is everywhere, one air object per cell. Its kind depends on the
  // ground below, which does not change after this point: sea, beach,
  // mountain, or flat land (at the foot of a mountain or not).
  void _placeAir() {
    for (int x = 0; x < model.width; x++) {
      for (int y = 0; y < model.height; y++) {
        model.add(_airFor(Cell(x, y)));
      }
    }
  }

  AirModel _airFor(Cell cell) {
    Type? ground = model.groundTypeAt(cell);

    if (ground == BeachModel) {
      return AirCoastModel(
        gameModelRef: model,
        cell: cell,
        landward: directionTowards(model, cell, _isLand),
      );
    }
    if (_isMountain(ground)) {
      return AirMountainModel(gameModelRef: model, cell: cell);
    }
    if (ground == SoilModel) {
      Direction? mountainward = directionTowards(model, cell, _makesUpdraft);
      // flat land right at the foot of a real mountain gets the updraft
      if (mountainward != null) {
        return AirFoothillModel(gameModelRef: model, cell: cell, mountainward: mountainward);
      }
      return AirLandModel(gameModelRef: model, cell: cell);
    }
    return AirSeaModel(gameModelRef: model, cell: cell);
  }

  bool _isMountain(Type? ground) {
    return ground == HeightAreaLowModel ||
        ground == HeightAreaMediumModel ||
        ground == HeightAreaHighModel;
  }

  // Only real mountains pull an updraft; low hills do not make wind.
  bool _makesUpdraft(Type? ground) {
    return ground == HeightAreaMediumModel || ground == HeightAreaHighModel;
  }

  bool _isLand(Type? ground) {
    return ground == SoilModel || _isMountain(ground);
  }

  /// The direction from [cell] towards the ground [isTarget] accepts: the
  /// directions of all such neighbors (as vectors of length 1) added up, then
  /// the direction closest to the sum. Null when no such ground is near.
  static Direction? directionTowards(
      GameModel model, Cell cell, bool Function(Type? ground) isTarget) {
    double sumX = 0;
    double sumY = 0;
    for (Direction direction in Direction.values) {
      if (isTarget(model.groundTypeAt(cell + direction.step))) {
        sumX += direction.unitX;
        sumY += direction.unitY;
      }
    }
    if (sumX == 0 && sumY == 0) {
      return null;
    }
    return Direction.closestTo(sumX, sumY);
  }

  // The highest land becomes mountains: the very highest cells are high,
  // around them medium and then low. The height map is smooth, so the peaks
  // end up in the middle of the mountain areas.
  void _placeMountainsOnLand(List<List<double>> heightMap, List<double> sortedHeights) {
    var mountain = kGameConfiguration.mountain;
    double highThreshold = _heightAbovePercentage(sortedHeights, mountain.highPercentage);
    double mediumThreshold =
        _heightAbovePercentage(sortedHeights, mountain.highPercentage + mountain.mediumPercentage);
    double lowThreshold = _heightAbovePercentage(sortedHeights,
        mountain.highPercentage + mountain.mediumPercentage + mountain.lowPercentage);

    for (int x = 0; x < model.width; x++) {
      for (int y = 0; y < model.height; y++) {
        Cell cell = Cell(x, y);
        bool isLand = model.getAgentAtCell(cell, SeedableModel.staticLayerId) != null;
        if (!isLand) {
          continue;
        }
        double cellHeight = heightMap[x][y];
        if (cellHeight >= highThreshold) {
          model.add(HeightAreaHighModel(gameModelRef: model, cell: cell));
        } else if (cellHeight >= mediumThreshold) {
          model.add(HeightAreaMediumModel(gameModelRef: model, cell: cell));
        } else if (cellHeight >= lowThreshold) {
          model.add(HeightAreaLowModel(gameModelRef: model, cell: cell));
        }
      }
    }
  }

  // The height that only the given percentage of the map lies above.
  double _heightAbovePercentage(List<double> sortedHeights, double percentage) {
    int index = (sortedHeights.length * (1 - percentage / 100.0)).floor();
    index = index.clamp(0, sortedHeights.length - 1);
    return sortedHeights[index];
  }

  // A few round rocky islands in open water, away from the shore.
  void _placeRockyIslands() {
    var mountain = kGameConfiguration.mountain;
    int placed = 0;
    for (int attempt = 0; attempt < 500 && placed < mountain.islandCount; attempt++) {
      Cell center = Cell(_random.nextInt(model.width), _random.nextInt(model.height));
      // one cell of water more than the widest rim, so the island never touches land
      if (_isOpenWater(center, mountain.islandLowRadius + 1.6)) {
        _placeIsland(center);
        placed++;
      }
    }
  }

  // True if every cell within the radius is water without a height area.
  bool _isOpenWater(Cell center, double radius) {
    int range = radius.ceil();
    for (int dx = -range; dx <= range; dx++) {
      for (int dy = -range; dy <= range; dy++) {
        Cell cell = Cell(center.x + dx, center.y + dy);
        if (center.distanceTo(cell) > radius) {
          continue;
        }
        // cells outside of the map are empty, so they are no water
        AgentModel? patch = model.getAgentAtCell(cell, PatchModel.staticLayerId);
        bool isWater = patch is WaterModel || patch is FlatWaterModel;
        if (!isWater || model.getAgentAtCell(cell, HeightAreaModel.staticLayerId) != null) {
          return false;
        }
      }
    }
    return true;
  }

  void _placeIsland(Cell center) {
    var mountain = kGameConfiguration.mountain;
    int range = (mountain.islandLowRadius + 1).ceil();
    for (int dx = -range; dx <= range; dx++) {
      for (int dy = -range; dy <= range; dy++) {
        Cell cell = Cell(center.x + dx, center.y + dy);
        double distance = center.distanceTo(cell);
        // the rim is a bit uneven, so the island does not look like a circle
        double rim = mountain.islandLowRadius + _random.nextDouble() * 0.6;
        if (distance <= mountain.islandHighRadius) {
          model.add(HeightAreaHighModel(gameModelRef: model, cell: cell));
        } else if (distance <= mountain.islandMediumRadius) {
          model.add(HeightAreaMediumModel(gameModelRef: model, cell: cell));
        } else if (distance <= rim) {
          model.add(HeightAreaLowModel(gameModelRef: model, cell: cell));
        }
      }
    }
  }

  // ---- connected land ----

  bool _isSoil(Cell cell) {
    return model.getAgentAtCell(cell, SeedableModel.staticLayerId) != null;
  }

  // Land the player can walk on. Rocky islands do not count: they stand in
  // the water and stay out of reach on purpose.
  bool _isWalkableLand(Cell cell) {
    bool onLand =
        _isSoil(cell) || model.getAgentAtCell(cell, PatchModel.staticLayerId) is BeachModel;
    return onLand && walking.canEnterCell(model, cell);
  }

  // Land pieces that are too small for a bridge become water.
  void _floodSmallIslands() {
    List<Set<Cell>> regions = _findRegions(_isSoil);
    if (regions.isEmpty) {
      return;
    }
    Set<Cell> mainLand = _largest(regions);
    for (Set<Cell> region in regions) {
      if (region != mainLand && region.length < kGameConfiguration.world.minIslandSize) {
        for (Cell cell in region) {
          model.remove(model.getAgentAtCell(cell, SeedableModel.staticLayerId)!);
          model.add(WaterModel(gameModelRef: model, cell: cell));
        }
      }
    }
  }

  // A land bridge three cells wide. One cell wide would turn into water again
  // when the beaches are made; this way it gets sandy edges and soil inside.
  void _buildLandBridge(Cell center) {
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        Cell cell = Cell(center.x + dx, center.y + dy);
        if (cell.isInsideMap && !_isSoil(cell)) {
          _replacePatchWithSoil(cell);
        }
      }
    }
  }

  // Makes a cell walkable land: water becomes soil, a high peak becomes medium.
  void _buildWalkablePassage(Cell cell) {
    if (!_isSoil(cell) && model.getAgentAtCell(cell, PatchModel.staticLayerId) is! BeachModel) {
      _replacePatchWithSoil(cell);
    }
    AgentModel? area = model.getAgentAtCell(cell, HeightAreaModel.staticLayerId);
    if (area is HeightAreaHighModel) {
      model.remove(area);
      model.add(HeightAreaMediumModel(gameModelRef: model, cell: cell));
    }
  }

  void _replacePatchWithSoil(Cell cell) {
    AgentModel? patch = model.getAgentAtCell(cell, PatchModel.staticLayerId);
    if (patch != null) {
      model.remove(patch);
    }
    model.add(SoilModel(gameModelRef: model, cell: cell));
  }

  /// Connects every region with the largest one, one bridge at a time, until
  /// only one region is left. [belongs] tells which cells form the regions;
  /// [buildBridge] must make a cell belong to a region.
  void _connectRegions(bool Function(Cell) belongs, void Function(Cell) buildBridge) {
    // a limit, so a mistake can never hang the game
    for (int round = 0; round < 1000; round++) {
      List<Set<Cell>> regions = _findRegions(belongs);
      if (regions.length <= 1) {
        return;
      }
      List<Cell> bridge = _shortestBridge(_largest(regions), belongs);
      if (bridge.isEmpty) {
        return;
      }
      for (Cell cell in bridge) {
        buildBridge(cell);
      }
    }
  }

  /// Groups of cells that belong together. Two cells are neighbors when they
  /// share an edge; corners do not count, the player could not pass there.
  List<Set<Cell>> _findRegions(bool Function(Cell) belongs) {
    List<Set<Cell>> regions = [];
    Set<Cell> visited = {};
    for (int x = 0; x < model.width; x++) {
      for (int y = 0; y < model.height; y++) {
        Cell start = Cell(x, y);
        if (!belongs(start) || visited.contains(start)) {
          continue;
        }
        Set<Cell> region = {};
        List<Cell> toVisit = [start];
        visited.add(start);
        while (toVisit.isNotEmpty) {
          Cell cell = toVisit.removeLast();
          region.add(cell);
          for (Cell next in _edgeNeighbors(cell)) {
            if (belongs(next) && visited.add(next)) {
              toVisit.add(next);
            }
          }
        }
        regions.add(region);
      }
    }
    return regions;
  }

  /// The cells between [region] and the nearest cell of another region, on
  /// the shortest way. Empty if no other region can be reached.
  List<Cell> _shortestBridge(Set<Cell> region, bool Function(Cell) belongs) {
    // search outwards from the whole region, ring by ring
    Map<Cell, Cell> cameFrom = {};
    Set<Cell> visited = Set.of(region);
    Queue<Cell> toVisit = Queue.of(region);
    while (toVisit.isNotEmpty) {
      Cell cell = toVisit.removeFirst();
      for (Cell next in _edgeNeighbors(cell)) {
        if (!visited.add(next)) {
          continue;
        }
        cameFrom[next] = cell;
        if (belongs(next)) {
          // reached another region: walk back and collect the cells in between
          List<Cell> bridge = [];
          Cell? step = cell;
          while (step != null && !region.contains(step)) {
            bridge.add(step);
            step = cameFrom[step];
          }
          return bridge;
        }
        toVisit.add(next);
      }
    }
    return [];
  }

  List<Cell> _edgeNeighbors(Cell cell) {
    List<Cell> neighbors = [
      Cell(cell.x + 1, cell.y),
      Cell(cell.x - 1, cell.y),
      Cell(cell.x, cell.y + 1),
      Cell(cell.x, cell.y - 1),
    ];
    return neighbors.where((neighbor) => neighbor.isInsideMap).toList();
  }

  Set<Cell> _largest(List<Set<Cell>> regions) {
    Set<Cell> largest = regions.first;
    for (Set<Cell> region in regions) {
      if (region.length > largest.length) {
        largest = region;
      }
    }
    return largest;
  }
}
