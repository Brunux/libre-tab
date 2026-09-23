import 'package:flutter/material.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';

/// Font families from docs/DESIGN.md, bundled under assets/fonts/.
abstract final class AppFonts {
  static const body = 'AtkinsonHyperlegible';
  static const display = 'Fraunces';
  static const mono = 'JetBrainsMono';

  /// Fraunces is a variable font: `fontWeight` alone doesn't move its
  /// weight axis, so set it (and optical size) explicitly.
  static TextStyle displayStyle(double size, Color color) => TextStyle(
    fontFamily: display,
    fontSize: size,
    fontWeight: FontWeight.w600,
    fontVariations: [
      const FontVariation.weight(600),
      FontVariation.opticalSize(size.clamp(9, 144)),
    ],
    color: color,
  );
}

enum AppThemeVariant {
  dark(LibreColors.dark, Brightness.dark),
  redNight(LibreColors.redNight, Brightness.dark),
  light(LibreColors.light, Brightness.light);

  const AppThemeVariant(this.colors, this.brightness);

  final LibreColors colors;
  final Brightness brightness;
}

ThemeData buildTheme(AppThemeVariant variant) {
  final c = variant.colors;
  final scheme = ColorScheme(
    brightness: variant.brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
    secondary: c.chord,
    onSecondary: c.onAccent,
    error: switch (variant) {
      AppThemeVariant.dark => const Color(0xFFFF8A80),
      AppThemeVariant.redNight => c.text,
      AppThemeVariant.light => const Color(0xFFB3261E),
    },
    onError: c.onAccent,
    surface: c.bg,
    onSurface: c.text,
    onSurfaceVariant: c.muted,
    outline: c.line,
    outlineVariant: c.line,
    surfaceContainerLowest: c.bg,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.surface2,
    surfaceContainerHighest: c.surface2,
  );

  final base = ThemeData(
    colorScheme: scheme,
    fontFamily: AppFonts.body,
    scaffoldBackgroundColor: c.bg,
    extensions: [c],
  );

  final textTheme = base.textTheme.copyWith(
    headlineLarge: AppFonts.displayStyle(
      34,
      c.text,
    ).copyWith(letterSpacing: -0.5),
    headlineMedium: AppFonts.displayStyle(26, c.text),
    headlineSmall: AppFonts.displayStyle(24, c.text),
  );

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: textTheme.headlineSmall,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 76,
      backgroundColor: c.surface,
      indicatorColor: c.surface2,
      surfaceTintColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? c.accent : c.muted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: states.contains(WidgetState.selected) ? c.accent : c.muted,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.accent,
      foregroundColor: c.onAccent,
      extendedTextStyle: const TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),
    dividerTheme: DividerThemeData(color: c.line, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.line),
      ),
    ),
  );
}
