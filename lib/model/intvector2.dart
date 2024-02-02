class IntVector2 {
  final int x;
  final int y;

  IntVector2(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntVector2 && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  IntVector2 operator +(IntVector2 other) => IntVector2(x + other.x, y + other.y);
  IntVector2 operator -(IntVector2 other) => IntVector2(x - other.x, y - other.y);

  // Add more operations as needed.

  @override
  String toString() => 'IntVector2(x: $x, y: $y)';
}
