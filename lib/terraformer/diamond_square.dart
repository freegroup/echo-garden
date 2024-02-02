import 'dart:math';

List<List<double>> diamondSquare(int width, int height) {
  int size = _calculateMinimumSize(width, height);
  final int n = pow(2, size).toInt() + 1; // Ensure grid size is 2^n + 1
  List<List<double>> map = List.generate(n, (_) => List.filled(n, 0.0));
  final Random rand = Random();
  double scale = 1.0;

  // Initialize corners
  map[0][0] = rand.nextDouble();
  map[0][n - 1] = rand.nextDouble();
  map[n - 1][0] = rand.nextDouble();
  map[n - 1][n - 1] = rand.nextDouble();

  for (int sideLength = n - 1; sideLength >= 2; sideLength ~/= 2, scale /= 2.0) {
    int halfSide = sideLength ~/ 2;

    // Diamond step
    for (int x = 0; x < n - 1; x += sideLength) {
      for (int y = 0; y < n - 1; y += sideLength) {
        double avg = (map[x][y] +
                map[x + sideLength][y] +
                map[x][y + sideLength] +
                map[x + sideLength][y + sideLength]) /
            4.0;
        map[x + halfSide][y + halfSide] = avg + (rand.nextDouble() * 2 * scale - scale);
      }
    }

    // Square step
    for (int x = 0; x < n; x += halfSide) {
      for (int y = (x + halfSide) % sideLength; y < n; y += sideLength) {
        double avg = map[(x - halfSide + n) % n][y] +
            map[(x + halfSide) % n][y] +
            map[x][(y + halfSide) % n] +
            map[x][(y - halfSide + n) % n];
        avg /= 4.0;
        map[x][y] = avg + (rand.nextDouble() * 2 * scale - scale);
      }
    }
  }

  return map;
}

int _calculateMinimumSize(int width, int height) {
  int maxDimension = max(width, height);
  int size = 0;
  // Find the smallest size such that (2^size + 1) >= maxDimension
  while ((pow(2, size) + 1) < maxDimension) {
    size++;
  }
  return size;
}
