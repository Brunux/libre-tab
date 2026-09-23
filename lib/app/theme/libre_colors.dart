import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The color tokens from docs/DESIGN.md, attached to [ThemeData] as an
/// extension so widgets can read e.g. `context.colors.chord`.
@immutable
class LibreColors extends ThemeExtension<LibreColors> {
  const LibreColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.text,
    required this.muted,
    required this.chord,
    required this.accent,
    required this.onAccent,
    required this.good,
  });

  static const dark = LibreColors(
    bg: Color(0xFF100D0A),
    surface: Color(0xFF1B1712),
    surface2: Color(0xFF282119),
    line: Color(0xFF3A3027),
    text: Color(0xFFF4EDE3),
    muted: Color(0xFFA99C8B),
    chord: Color(0xFFF4A93A),
    accent: Color(0xFFF4A93A),
    onAccent: Color(0xFF1A1107),
    good: Color(0xFF7BD389),
  );

  /// Only red hues, to protect night vision. "Good" is shown by brightness.
  static const redNight = LibreColors(
    bg: Color(0xFF000000),
    surface: Color(0xFF120303),
    surface2: Color(0xFF1E0606),
    line: Color(0xFF3A0C0A),
    text: Color(0xFFFF6A5C),
    muted: Color(0xFFDA4C40),
    chord: Color(0xFFFFA094),
    accent: Color(0xFFFF5A4B),
    onAccent: Color(0xFF000000),
    good: Color(0xFFFFC2B9),
  );

  static const light = LibreColors(
    bg: Color(0xFFFAF6EF),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF1EADF),
    line: Color(0xFFE3D8C8),
    text: Color(0xFF1E1812),
    muted: Color(0xFF6A5D4F),
    chord: Color(0xFFA94C06),
    accent: Color(0xFFB8480A),
    onAccent: Color(0xFFFFFFFF),
    good: Color(0xFF1F7A3B),
  );

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color line;
  final Color text;
  final Color muted;
  final Color chord;
  final Color accent;
  final Color onAccent;
  final Color good;

  @override
  LibreColors copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? line,
    Color? text,
    Color? muted,
    Color? chord,
    Color? accent,
    Color? onAccent,
    Color? good,
  }) {
    return LibreColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      line: line ?? this.line,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      chord: chord ?? this.chord,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      good: good ?? this.good,
    );
  }

  @override
  LibreColors lerp(LibreColors? other, double t) {
    if (other == null) return this;
    return LibreColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      line: Color.lerp(line, other.line, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      chord: Color.lerp(chord, other.chord, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      good: Color.lerp(good, other.good, t)!,
    );
  }

  List<Color> get _tokens => [
    bg, surface, surface2, line, text, muted, chord, accent, onAccent, good, //
  ];

  @override
  bool operator ==(Object other) =>
      other is LibreColors && listEquals(other._tokens, _tokens);

  @override
  int get hashCode => Object.hashAll(_tokens);
}

extension LibreColorsX on BuildContext {
  LibreColors get colors => Theme.of(this).extension<LibreColors>()!;
}
