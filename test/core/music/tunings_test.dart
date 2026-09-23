import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/core/music/tuner_reading.dart';
import 'package:libre_tab/core/music/tunings.dart';

void main() {
  group('tunings', () {
    test('notes, low to high', () {
      expect(Tuning.standard.notes, 'E A D G B E');
      expect(Tuning.halfStepDown.notes, 'E♭ A♭ D♭ G♭ B♭ E♭');
      expect(Tuning.dropD.notes, 'D A D G B E');
      expect(Tuning.dadgad.notes, 'D A D G A D');
      expect(Tuning.openG.notes, 'D G D G B D');
      expect(Tuning.openD.notes, 'D A D F♯ A D');
    });

    test('standard tuning frequencies at A4 = 440', () {
      final hz = Tuning.standard.strings.map((s) => s.frequency());
      expect(
        hz.map((f) => f.toStringAsFixed(2)),
        ['82.41', '110.00', '146.83', '196.00', '246.94', '329.63'],
      );
    });

    test('octaves', () {
      expect(Tuning.standard.strings.map((s) => '$s'), [
        'E2', 'A2', 'D3', 'G3', 'B3', 'E4', //
      ]);
    });

    test('a different A4 reference moves every string', () {
      expect(const GuitarString(69).frequency(432), 432);
      expect(const GuitarString(45).frequency(432), closeTo(108, 0.001));
    });
  });

  group('TunerReading', () {
    test('auto-detect picks the nearest string', () {
      final r = TunerReading.of(108, tuning: Tuning.standard);
      expect(r.stringIndex, 1); // A
      expect(r.target.name, 'A');
      expect(r.cents, closeTo(-31.8, 0.1));
      expect(r.tooLow, isTrue);
    });

    test('a locked string is always the target, even far away', () {
      final r = TunerReading.of(
        108,
        tuning: Tuning.standard,
        lockedString: 0,
      );
      expect(r.target.name, 'E');
      expect(r.cents, greaterThan(400)); // A2 is far above E2
      expect(r.tooHigh, isTrue);
    });

    test('within ±5 cents is in tune', () {
      final e4 = const GuitarString(64).frequency();
      for (final (hz, inTune) in [
        (e4, true),
        (e4 * 1.0028, true), // +4.8 cents
        (e4 * 1.0035, false), // +6.0 cents
      ]) {
        expect(
          TunerReading.of(hz, tuning: Tuning.standard).withinTolerance,
          inTune,
          reason: '$hz',
        );
      }
    });

    test('drop D: a low D is its own string, not a flat E', () {
      final r = TunerReading.of(73.42, tuning: Tuning.dropD);
      expect(r.stringIndex, 0);
      expect(r.cents.abs(), lessThan(1));
    });

    test('the A4 reference changes what counts as in tune', () {
      expect(
        TunerReading.of(110, tuning: Tuning.standard).withinTolerance,
        isTrue,
      );
      expect(
        TunerReading.of(110, tuning: Tuning.standard, a4: 432).cents,
        closeTo(31.8, 0.1),
      );
    });
  });

  group('TunerSmoother', () {
    test('the median hides a one-frame glitch', () {
      final s = TunerSmoother();
      [110.0, 110.2, 110.1, 110.3].forEach(s.add);
      expect(s.add(115), closeTo(110.2, 0.11));
    });

    test('silence clears the history', () {
      final s = TunerSmoother()..add(110);
      expect(s.add(null), isNull);
      expect(s.add(82.4), 82.4);
    });

    test('plucking another string starts over straight away', () {
      final s = TunerSmoother();
      for (var i = 0; i < 5; i++) {
        s.add(110);
      }
      expect(s.add(329.6), 329.6);
    });

    test('in tune only after holding the zone for 300 ms', () {
      final s = TunerSmoother();
      final good = TunerReading.of(110, tuning: Tuning.standard);
      final off = TunerReading.of(108, tuning: Tuning.standard);
      const ms = Duration(milliseconds: 1);

      expect(s.inTune(good, ms * 0), isFalse);
      expect(s.inTune(good, ms * 200), isFalse);
      expect(s.inTune(good, ms * 300), isTrue);

      expect(s.inTune(off, ms * 350), isFalse); // left the zone
      expect(s.inTune(good, ms * 400), isFalse); // clock restarted
      expect(s.inTune(good, ms * 700), isTrue);

      expect(s.inTune(null, ms * 710), isFalse); // silence
      s.reset();
      expect(s.inTune(good, ms * 720), isFalse);
    });
  });
}
