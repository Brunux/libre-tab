import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/app/theme/app_theme.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';

/// WCAG contrast ratio between two opaque colors.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('titles use Fraunces with its weight axis set to 600', () {
    final style = buildTheme(AppThemeVariant.dark).textTheme.headlineLarge!;
    expect(style.fontFamily, AppFonts.display);
    expect(style.fontVariations, contains(const FontVariation.weight(600)));
  });

  for (final variant in AppThemeVariant.values) {
    group(variant.name, () {
      final c = variant.colors;

      test('theme carries its color tokens', () {
        final theme = buildTheme(variant);
        expect(theme.extension<LibreColors>(), c);
        expect(theme.colorScheme.primary, c.accent);
        expect(theme.colorScheme.brightness, variant.brightness);
        expect(theme.scaffoldBackgroundColor, c.bg);
      });

      test('text, muted and chord colors are readable (≥ 4.5:1)', () {
        // surface2 backs the song screen's dock and the list's key badges.
        for (final background in [c.bg, c.surface, c.surface2]) {
          expect(contrast(c.text, background), greaterThanOrEqualTo(4.5));
          expect(contrast(c.muted, background), greaterThanOrEqualTo(4.5));
          expect(contrast(c.chord, background), greaterThanOrEqualTo(4.5));
        }
      });

      test('text on accent buttons is readable (≥ 4.5:1)', () {
        expect(contrast(c.onAccent, c.accent), greaterThanOrEqualTo(4.5));
      });

      test('"in tune" color stands out from the background (≥ 3:1)', () {
        expect(contrast(c.good, c.bg), greaterThanOrEqualTo(3));
      });
    });
  }
}
