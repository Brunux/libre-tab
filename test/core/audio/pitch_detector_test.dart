import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/core/audio/pitch_detector.dart';
import 'package:libre_tab/core/music/tuner_reading.dart';
import 'package:libre_tab/core/music/tunings.dart';

const sampleRate = 44100.0;
const frameSize = 4096;

/// A synthetic note: [harmonics] are the amplitudes of the fundamental,
/// 2nd, 3rd… partials. Guitar strings have a strong 2nd harmonic.
Float64List tone(
  double frequency, {
  List<double> harmonics = const [1],
  double amplitude = 0.5,
  double noise = 0,
  int seed = 1,
}) {
  final random = math.Random(seed);
  final phase = random.nextDouble() * 2 * math.pi;
  final total = harmonics.reduce((a, b) => a + b);
  return Float64List.fromList([
    for (var i = 0; i < frameSize; i++)
      amplitude *
              [
                for (var h = 0; h < harmonics.length; h++)
                  harmonics[h] *
                      math.sin(
                        2 * math.pi * frequency * (h + 1) * i / sampleRate +
                            phase * (h + 1),
                      ),
              ].reduce((a, b) => a + b) /
              total +
          noise * (random.nextDouble() * 2 - 1),
  ]);
}

/// A plucked acoustic string: the 2nd harmonic louder than the fundamental.
const guitarHarmonics = [0.6, 1.0, 0.5, 0.35, 0.2, 0.1];

double cents(PitchResult? result, double expected) {
  expect(result, isNotNull, reason: '$expected Hz not detected');
  return TunerReading.centsBetween(result!.frequency, expected);
}

void main() {
  final detector = PitchDetector(sampleRate: sampleRate);
  final allStrings = {
    for (final tuning in Tuning.values)
      for (final s in tuning.strings) s.frequency(),
  };

  test('pure tones on every string of every tuning, within 1 cent', () {
    for (final f in allStrings) {
      expect(
        cents(detector.detect(tone(f)), f).abs(),
        lessThan(1),
        reason: '$f',
      );
    }
  });

  test('guitar-like tones with a strong 2nd harmonic: no octave jumps', () {
    for (final f in allStrings) {
      final off = cents(
        detector.detect(tone(f, harmonics: guitarHarmonics)),
        f,
      );
      expect(off.abs(), lessThan(2), reason: '$f Hz read $off cents off');
    }
  });

  test('detuned strings are measured, not snapped to the note', () {
    for (final detune in [-40.0, -12.0, -3.0, 3.0, 12.0, 40.0]) {
      final e2 = const GuitarString(40).frequency();
      final f = e2 * math.pow(2, detune / 1200);
      final off = cents(
        detector.detect(tone(f, harmonics: guitarHarmonics)),
        e2,
      );
      expect(off, closeTo(detune, 1.5), reason: '$detune cents');
    }
  });

  test('works with background noise around the campfire', () {
    for (final f in [82.41, 110.0, 196.0, 329.63]) {
      final off = cents(
        detector.detect(
          tone(f, harmonics: guitarHarmonics, noise: 0.05, seed: f.round()),
        ),
        f,
      );
      expect(off.abs(), lessThan(3), reason: '$f');
    }
  });

  test('silence and very quiet sound give nothing', () {
    expect(detector.detect(Float64List(frameSize)), isNull);
    expect(detector.detect(tone(110, amplitude: 0.002)), isNull);
  });

  test('pure noise gives nothing', () {
    final random = math.Random(7);
    final noise = Float64List.fromList([
      for (var i = 0; i < frameSize; i++) random.nextDouble() - 0.5,
    ]);
    expect(detector.detect(noise), isNull);
  });

  test('a tiny frame gives nothing instead of crashing', () {
    expect(detector.detect(Float64List(3)), isNull);
  });

  test('fast enough for ~20 readings a second', () {
    final frame = tone(82.41, harmonics: guitarHarmonics);
    detector.detect(frame); // warm up
    final watch = Stopwatch()..start();
    for (var i = 0; i < 10; i++) {
      detector.detect(frame);
    }
    expect(watch.elapsedMilliseconds / 10, lessThan(50));
  });
}
