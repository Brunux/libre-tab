import 'dart:math' as math;

import 'package:libre_tab/core/music/tunings.dart';

/// What the tuner shows for one detected frequency.
final class TunerReading {
  const TunerReading({
    required this.frequency,
    required this.stringIndex,
    required this.target,
    required this.cents,
  });

  /// Works out which string is being tuned and how far off it is.
  ///
  /// With [lockedString] set, every sound is measured against that string.
  /// Otherwise the string closest to [frequency] is picked (auto-detect).
  factory TunerReading.of(
    double frequency, {
    required Tuning tuning,
    int? lockedString,
    double a4 = 440,
  }) {
    final strings = tuning.strings;
    var index = lockedString ?? 0;
    if (lockedString == null) {
      var best = double.infinity;
      for (var i = 0; i < strings.length; i++) {
        final off = centsBetween(frequency, strings[i].frequency(a4)).abs();
        if (off < best) {
          best = off;
          index = i;
        }
      }
    }
    final target = strings[index];
    return TunerReading(
      frequency: frequency,
      stringIndex: index,
      target: target,
      cents: centsBetween(frequency, target.frequency(a4)),
    );
  }

  /// Within this many cents counts as in tune (docs/TECH_STACK.md § Tuner).
  static const inTuneCents = 5.0;

  final double frequency;

  /// 0 = 6th (lowest) string … 5 = 1st.
  final int stringIndex;
  final GuitarString target;

  /// How far off: negative is flat (too low), positive is sharp.
  final double cents;

  bool get withinTolerance => cents.abs() <= inTuneCents;
  bool get tooLow => cents < -inTuneCents;
  bool get tooHigh => cents > inTuneCents;

  static double centsBetween(double frequency, double reference) =>
      1200 * math.log(frequency / reference) / math.ln2;
}

/// Steadies the readings and decides when a string is really in tune.
///
/// The median of the last few frequencies hides single-frame glitches;
/// "in tune" needs [hold] inside the tolerance so a lucky frame doesn't
/// count (docs/TECH_STACK.md: ±5 cents for ~300 ms).
class TunerSmoother {
  TunerSmoother({
    this.window = 5,
    this.hold = const Duration(milliseconds: 300),
  });

  final int window;
  final Duration hold;

  final _recent = <double>[];
  Duration? _inZoneSince;

  /// Adds a detected frequency (null = silence). Returns the smoothed
  /// frequency, or null while silent.
  double? add(double? frequency) {
    if (frequency == null) {
      _recent.clear();
      _inZoneSince = null;
      return null;
    }
    // A big jump (another string plucked) starts over.
    if (_recent.isNotEmpty &&
        TunerReading.centsBetween(frequency, _recent.last).abs() > 100) {
      _recent.clear();
    }
    _recent.add(frequency);
    if (_recent.length > window) _recent.removeAt(0);
    final sorted = [..._recent]..sort();
    return sorted[sorted.length ~/ 2];
  }

  /// Whether [reading] has been within tolerance for [hold] up to [now].
  bool inTune(TunerReading? reading, Duration now) {
    if (reading == null || !reading.withinTolerance) {
      _inZoneSince = null;
      return false;
    }
    _inZoneSince ??= now;
    return now - _inZoneSince! >= hold;
  }

  void reset() {
    _recent.clear();
    _inZoneSince = null;
  }
}
