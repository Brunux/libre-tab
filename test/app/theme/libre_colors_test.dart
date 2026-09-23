import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';

void main() {
  const a = LibreColors.dark;
  const b = LibreColors.light;

  test('copyWith replaces only the given colors', () {
    final changed = a.copyWith(chord: const Color(0xFF123456));
    expect(changed.chord, const Color(0xFF123456));
    expect(changed.bg, a.bg);
    expect(changed.copyWith(chord: a.chord), a);
    expect(a.copyWith(), a);
  });

  test('value equality', () {
    final copy = a.copyWith(bg: a.bg);
    expect(identical(copy, a), isFalse);
    expect(copy, a);
    expect(copy.hashCode, a.hashCode);
    expect(a, isNot(b));
  });

  group('lerp (animates theme switches)', () {
    test('ends are the two themes', () {
      expect(a.lerp(b, 0), a);
      expect(a.lerp(b, 1), b);
    });

    test('halfway mixes every token', () {
      final mid = a.lerp(b, 0.5);
      expect(mid.bg, Color.lerp(a.bg, b.bg, 0.5));
      expect(mid.good, Color.lerp(a.good, b.good, 0.5));
      expect(mid.onAccent, Color.lerp(a.onAccent, b.onAccent, 0.5));
    });

    test('null other keeps this theme', () {
      expect(a.lerp(null, 0.5), a);
    });
  });
}
