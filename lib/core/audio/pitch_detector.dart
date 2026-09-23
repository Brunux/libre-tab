import 'dart:math' as math;
import 'dart:typed_data';

/// Finds the pitch of a block of audio with the McLeod Pitch Method
/// ("A Smarter Way to Find Pitch", McLeod & Wyvill, 2005): a normalised
/// square difference function whose first high peak marks the period.
/// Robust to the strong 2nd harmonic of guitar strings, so it rarely jumps
/// an octave. Pure Dart; runs on a background isolate in the app.
class PitchDetector {
  PitchDetector({
    required this.sampleRate,
    this.minFrequency = 60,
    this.maxFrequency = 1000,
    this.clarityThreshold = 0.8,
    this.silenceRms = 0.005,
  });

  final double sampleRate;

  /// Lowest pitch looked for: a little below Drop D's low D (73 Hz).
  final double minFrequency;

  /// Highest pitch looked for: well above the high E string (330 Hz).
  final double maxFrequency;

  /// How periodic the sound must be (0–1) to count as a note.
  final double clarityThreshold;

  /// Quieter than this (root mean square, samples in −1…1) is silence.
  final double silenceRms;

  /// Picks the first peak at least this high relative to the highest one.
  static const _peakRatio = 0.9;

  /// The pitch of [samples], or null for silence, noise or no clear note.
  PitchResult? detect(Float64List samples) {
    final n = samples.length;
    if (n < 4) return null;

    var energy = 0.0;
    for (final s in samples) {
      energy += s * s;
    }
    if (math.sqrt(energy / n) < silenceRms) return null;

    final maxLag = math.min(n - 1, (sampleRate / minFrequency).ceil());
    final minLag = math.max(1, (sampleRate / maxFrequency).floor());
    final nsdf = _nsdf(samples, maxLag, energy);

    // Key maxima: the highest point of each positive region after the
    // first time the curve goes negative.
    final peaks = <int>[];
    var tau = 1;
    while (tau < maxLag && nsdf[tau] > 0) {
      tau++;
    }
    while (tau < maxLag) {
      while (tau < maxLag && nsdf[tau] <= 0) {
        tau++;
      }
      var best = -1;
      while (tau < maxLag && nsdf[tau] > 0) {
        if (best < 0 || nsdf[tau] > nsdf[best]) best = tau;
        tau++;
      }
      if (best >= minLag) peaks.add(best);
    }
    if (peaks.isEmpty) return null;

    final highest = peaks.map((p) => nsdf[p]).reduce(math.max);
    final chosen = peaks.firstWhere((p) => nsdf[p] >= _peakRatio * highest);

    // Parabolic interpolation around the peak for sub-sample accuracy.
    var period = chosen.toDouble();
    var clarity = nsdf[chosen];
    if (chosen > 0 && chosen < maxLag - 1) {
      final a = nsdf[chosen - 1];
      final b = nsdf[chosen];
      final c = nsdf[chosen + 1];
      final denominator = a - 2 * b + c;
      if (denominator != 0) {
        final shift = 0.5 * (a - c) / denominator;
        period += shift;
        clarity = b - 0.25 * (a - c) * shift;
      }
    }
    if (clarity < clarityThreshold) return null;
    return PitchResult(frequency: sampleRate / period, clarity: clarity);
  }

  /// n'(τ) = 2·r(τ) / m(τ), with m(τ) updated incrementally.
  static Float64List _nsdf(Float64List x, int maxLag, double energy) {
    final n = x.length;
    final result = Float64List(maxLag + 1);
    var m = 2 * energy;
    for (var tau = 0; tau <= maxLag; tau++) {
      if (tau > 0) m -= x[tau - 1] * x[tau - 1] + x[n - tau] * x[n - tau];
      var r = 0.0;
      for (var j = 0; j < n - tau; j++) {
        r += x[j] * x[j + tau];
      }
      result[tau] = m > 0 ? 2 * r / m : 0;
    }
    return result;
  }
}

final class PitchResult {
  const PitchResult({required this.frequency, required this.clarity});

  /// Hz.
  final double frequency;

  /// 0–1: how clearly periodic the sound is.
  final double clarity;
}
