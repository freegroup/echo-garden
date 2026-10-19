import 'dart:math';

import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/terraformer/plugins/terraform_water.dart';
import 'package:echo_garden/model/terraformer/terrain_map.dart';
import 'package:flutter_test/flutter_test.dart';

// A small map drawn by hand: '~' is water, '#' is soil; rows[y][x].
TerrainMap mapOf(List<String> rows) {
  TerrainMap map = TerrainMap(width: rows.first.length, height: rows.length, random: Random(0));
  for (int y = 0; y < rows.length; y++) {
    for (int x = 0; x < rows[y].length; x++) {
      map.setGround(Cell(x, y), rows[y][x] == '~' ? WaterModel : SoilModel);
    }
  }
  return map;
}

// The map drawn the same way, to compare it with the expectation.
List<String> drawn(TerrainMap map) {
  return [
    for (int y = 0; y < map.height; y++)
      [for (int x = 0; x < map.width; x++) map.groundAt(Cell(x, y)) == WaterModel ? '~' : '#']
          .join(),
  ];
}

// one pass of smoothing the coast
List<String> smoothed(List<String> rows) {
  TerrainMap map = mapOf(rows);
  TerraformWater().smoothGround(map, WaterModel, SoilModel);
  return drawn(map);
}

void main() {
  test('a single cell of land in the water goes under', () {
    expect(
        smoothed([
          '~~~~~',
          '~~~~~',
          '~~#~~',
          '~~~~~',
          '~~~~~',
        ]),
        [
          '~~~~~',
          '~~~~~',
          '~~~~~',
          '~~~~~',
          '~~~~~',
        ]);
  });

  test('a single hole of water in the land fills up', () {
    expect(
        smoothed([
          '#####',
          '#####',
          '##~##',
          '#####',
          '#####',
        ]),
        [
          '#####',
          '#####',
          '#####',
          '#####',
          '#####',
        ]);
  });

  test('a straight coast stays as it is', () {
    List<String> coast = [
      '~~~###',
      '~~~###',
      '~~~###',
      '~~~###',
    ];
    expect(smoothed(coast), coast);
  });

  test('a spike of land one cell wide is cut off the coast', () {
    expect(
        smoothed([
          '~~~~~~',
          '~~~~~~',
          '###~~~',
          '~~~~~~',
          '~~~~~~',
        ]),
        [
          '~~~~~~',
          '~~~~~~',
          '~~~~~~',
          '~~~~~~',
          '~~~~~~',
        ]);
  });

  test('a notch of water one cell wide in the coast is filled', () {
    expect(
        smoothed([
          '######',
          '######',
          '~~~###',
          '######',
          '######',
        ]),
        [
          '######',
          '######',
          '######',
          '######',
          '######',
        ]);
  });
}
