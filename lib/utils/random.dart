import 'dart:math';

// Generic function to pick a random element from a set
T? pickRandomElement<T>(Set<T> set) {
  if (set.isEmpty) {
    return null;
  }
  final randomIndex = Random().nextInt(set.length);
  return set.elementAt(randomIndex);
}

