import 'dart:collection';

import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/movement_mode.dart';
import 'package:echo_garden/model/objects/beach.dart';
import 'package:echo_garden/model/terraformer/terrain_map.dart';

/// One step of the terraformer, with one task.
///
/// The terraformer runs its plugins phase by phase: phase 00 of all plugins,
/// then phase 01 of all, and so on, always in the order of its list. A plugin
/// overrides only the phases it needs; by default a phase does nothing.
///
/// The base class offers the tools several plugins need.
abstract class TerraformPlugin {
  /// Fills the empty map. The generator comes first and makes the heights;
  /// the plugins after it build the first kinds of ground from them.
  void phase00Generate(TerrainMap map) {}

  /// Smooths what the generation made, if a plugin wants it for its part.
  void phase01Smooth(TerrainMap map) {}

  /// Connects what belongs together, e.g. pieces of land.
  void phase02Connect(TerrainMap map) {}

  /// Looks at the areas of the map and adjusts them: coasts, mountains, ways.
  void phase03Areas(TerrainMap map) {}

  /// Fills the model, after the terraformer has put the ground of the map
  /// into it.
  void phase04Populate(GameModel model, TerrainMap map) {}

  // ---- tools ----

  bool isSoil(TerrainMap map, Cell cell) => map.groundAt(cell) == SoilModel;

  // Land the player can walk on. Rocky islands do not count: they stand in
  // the water and stay out of reach on purpose.
  bool isWalkableLand(TerrainMap map, Cell cell) {
    Type? ground = map.groundAt(cell);
    bool onLand = ground == SoilModel || ground == BeachModel;
    return onLand && walking.canEnterGround(map.groundTypeAt(cell));
  }

  /// The neighbors that share an edge with the cell, inside of the map.
  List<Cell> edgeNeighbors(TerrainMap map, Cell cell) {
    List<Cell> neighbors = [
      Cell(cell.x + 1, cell.y),
      Cell(cell.x - 1, cell.y),
      Cell(cell.x, cell.y + 1),
      Cell(cell.x, cell.y - 1),
    ];
    return neighbors.where(map.isInside).toList();
  }

  /// How many of the eight neighbors of the cell have this ground.
  int countNeighborGround(TerrainMap map, Cell cell, Type ground) {
    int count = 0;
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        if (dx == 0 && dy == 0) continue; // not the cell itself
        if (map.groundAt(Cell(cell.x + dx, cell.y + dy)) == ground) {
          count++;
        }
      }
    }
    return count;
  }

  /// Smooths the border between the grounds [a] and [b], as a cellular
  /// automaton does: a cell of one of them takes the one that most cells of
  /// its 3 x 3 block (itself included) have; on a tie it stays. All cells
  /// decide at the same time, so the order does not matter. Other grounds are
  /// left alone and do not count.
  void smoothGround(TerrainMap map, Type a, Type b) {
    List<Cell> becomeA = [];
    List<Cell> becomeB = [];
    for (int x = 0; x < map.width; x++) {
      for (int y = 0; y < map.height; y++) {
        Cell cell = Cell(x, y);
        Type? ground = map.groundAt(cell);
        if (ground != a && ground != b) continue;

        int countA = 0;
        int countB = 0;
        for (int dx = -1; dx <= 1; dx++) {
          for (int dy = -1; dy <= 1; dy++) {
            Type? around = map.groundAt(Cell(x + dx, y + dy));
            if (around == a) countA++;
            if (around == b) countB++;
          }
        }
        if (countA > countB && ground != a) becomeA.add(cell);
        if (countB > countA && ground != b) becomeB.add(cell);
      }
    }
    for (Cell cell in becomeA) {
      map.setGround(cell, a);
    }
    for (Cell cell in becomeB) {
      map.setGround(cell, b);
    }
  }

  /// The heights of the cells of the map, sorted. The height grid is bigger
  /// than the map (its size must be 2^n + 1), so only the part that is used
  /// counts.
  List<double> sortedHeights(TerrainMap map) {
    List<double> sorted = [];
    for (int x = 0; x < map.width; x++) {
      for (int y = 0; y < map.height; y++) {
        sorted.add(map.heights[x][y]);
      }
    }
    sorted.sort();
    return sorted;
  }

  /// Connects every region with the largest one, one bridge at a time, until
  /// only one region is left. [belongs] tells which cells form the regions;
  /// [buildBridge] must make a cell belong to a region.
  void connectRegions(
      TerrainMap map, bool Function(Cell) belongs, void Function(Cell) buildBridge) {
    // a limit, so a mistake can never hang the game
    for (int round = 0; round < 1000; round++) {
      List<Set<Cell>> regions = findRegions(map, belongs);
      if (regions.length <= 1) {
        return;
      }
      List<Cell> bridge = shortestBridge(map, largest(regions), belongs);
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
  List<Set<Cell>> findRegions(TerrainMap map, bool Function(Cell) belongs) {
    List<Set<Cell>> regions = [];
    Set<Cell> visited = {};
    for (int x = 0; x < map.width; x++) {
      for (int y = 0; y < map.height; y++) {
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
          for (Cell next in edgeNeighbors(map, cell)) {
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
  List<Cell> shortestBridge(TerrainMap map, Set<Cell> region, bool Function(Cell) belongs) {
    // search outwards from the whole region, ring by ring
    Map<Cell, Cell> cameFrom = {};
    Set<Cell> visited = Set.of(region);
    Queue<Cell> toVisit = Queue.of(region);
    while (toVisit.isNotEmpty) {
      Cell cell = toVisit.removeFirst();
      for (Cell next in edgeNeighbors(map, cell)) {
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

  Set<Cell> largest(List<Set<Cell>> regions) {
    Set<Cell> largest = regions.first;
    for (Set<Cell> region in regions) {
      if (region.length > largest.length) {
        largest = region;
      }
    }
    return largest;
  }
}
