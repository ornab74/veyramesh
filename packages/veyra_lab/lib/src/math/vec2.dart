// SPDX-License-Identifier: GPL-3.0-only

import 'dart:math' as math;

final class Vec2 {
  const Vec2(this.x, this.y);

  static const Vec2 zero = Vec2(0, 0);
  static const Vec2 one = Vec2(1, 1);

  final double x;
  final double y;

  double get lengthSquared => x * x + y * y;
  double get length => math.sqrt(lengthSquared);

  Vec2 operator +(Vec2 other) => Vec2(x + other.x, y + other.y);
  Vec2 operator -(Vec2 other) => Vec2(x - other.x, y - other.y);
  Vec2 operator *(double scalar) => Vec2(x * scalar, y * scalar);
  Vec2 operator /(double scalar) => Vec2(x / scalar, y / scalar);

  Vec2 normalized({Vec2 fallback = zero}) {
    final double magnitude = length;
    return magnitude <= 1e-12 ? fallback : this / magnitude;
  }

  Vec2 limited(double maximum) {
    final double magnitude = length;
    return magnitude <= maximum ? this : normalized() * maximum;
  }

  Vec2 lerp(Vec2 other, double t) =>
      Vec2(x + (other.x - x) * t, y + (other.y - y) * t);

  double distanceTo(Vec2 other) => (this - other).length;

  Map<String, double> toJson() => <String, double>{'x': x, 'y': y};

  @override
  bool operator ==(Object other) => other is Vec2 && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Vec2($x, $y)';
}
