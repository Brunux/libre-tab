import 'package:flutter/material.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';

/// Font families from docs/DESIGN.md. Until the font files are bundled,
/// Flutter falls back to the platform font.
abstract final class AppFonts {
  static const body = 'AtkinsonHyperlegible';
  static const display = 'Fraunces';
  static const mono = 'JetBrainsMono';
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

  const display = TextStyle(
    fontFamily: AppFonts.display,
    fontWeight: FontWeight.w600,
  );
  final textTheme = base.textTheme.copyWith(
    headlineLarge: display.copyWith(
      fontSize: 34,
      letterSpacing: -0.5,
      color: c.text,
    ),
    headlineMedium: display.copyWith(fontSize: 26, color: c.text),
    headlineSmall: display.copyWith(fontSize: 24, color: c.text),
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
