import 'dart:math';

import 'package:echo_garden/model/terraformer/terraform_plugin.dart';
import 'package:echo_garden/model/terraformer/terrain_map.dart';

/// The generator: makes the heights of the map with the diamond-square
/// algorithm. Another generator could take its place.
class TerraformDiamondSquare extends TerraformPlugin {
  @override
  void phase00Generate(TerrainMap map) {
    map.heights = _diamondSquare(map.width, map.height, map.random);
  }

  /// Creates a height map with the diamond-square algorithm.
  ///
  /// The algorithm needs a square grid of size 2^k + 1, so the returned map is
  /// usually bigger than requested; use only the part you need. Using only a
  /// corner of the big map gives large, connected land masses.
  ///
  /// The same [random] seed always gives the same map. Read the map as
  /// `map[x][y]`.
  List<List<double>> _diamondSquare(int width, int height, Random random) {
    final int n = pow(2, _exponentFor(max(width, height))).toInt() + 1;
    List<List<double>> map = List.generate(n, (_) => List.filled(n, 0.0));

    // the corners start with random heights
    map[0][0] = random.nextDouble();
    map[0][n - 1] = random.nextDouble();
    map[n - 1][0] = random.nextDouble();
    map[n - 1][n - 1] = random.nextDouble();

    // how much a new point may differ from the average of its neighbors;
    // halved in every round, so the details get finer
    double roughness = 1.0;

    for (int sideLength = n - 1; sideLength >= 2; sideLength ~/= 2, roughness /= 2.0) {
      int halfSide = sideLength ~/ 2;

      // Diamond step: the middle of each square gets the average of its four
      // corners plus some randomness.
      for (int x = 0; x < n - 1; x += sideLength) {
        for (int y = 0; y < n - 1; y += sideLength) {
          double average = (map[x][y] +
                  map[x + sideLength][y] +
                  map[x][y + sideLength] +
                  map[x + sideLength][y + sideLength]) /
              4.0;
          map[x + halfSide][y + halfSide] = average + _randomOffset(random, roughness);
        }
      }

      // Square step: the middle of each edge gets the average of its four
      // neighbors plus some randomness. Neighbors beyond the border are taken
      // from the other side; the last row and column are the same points as
      // the first ones, therefore "n - 1".
      for (int x = 0; x < n - 1; x += halfSide) {
        for (int y = (x + halfSide) % sideLength; y < n - 1; y += sideLength) {
          double average = (map[(x - halfSide + n - 1) % (n - 1)][y] +
                  map[(x + halfSide) % (n - 1)][y] +
                  map[x][(y + halfSide) % (n - 1)] +
                  map[x][(y - halfSide + n - 1) % (n - 1)]) /
              4.0;
          double value = average + _randomOffset(random, roughness);
          map[x][y] = value;

          // keep the first and the last row/column the same
          if (x == 0) map[n - 1][y] = value;
          if (y == 0) map[x][n - 1] = value;
        }
      }
    }

    return map;
  }

  double _randomOffset(Random random, double roughness) {
    return random.nextDouble() * 2 * roughness - roughness;
  }

  /// The smallest k with 2^k + 1 >= size.
  int _exponentFor(int size) {
    int exponent = 0;
    while (pow(2, exponent) + 1 < size) {
      exponent++;
    }
    return exponent;
  }
}
