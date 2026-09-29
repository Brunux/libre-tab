import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/features/tuner/data/pitch_source.dart';

void main() {
  group('SilenceWatch (Android fills a silenced microphone with zeros)', () {
    List<bool?> feed(SilenceWatch watch, Iterable<int> samples) =>
        [for (final s in samples) watch.add(s)]..removeWhere((e) => e == null);

    test('a second of exact zeros is silenced, once', () {
      final watch = SilenceWatch(samples: 100);
      expect(feed(watch, List.filled(99, 0)), isEmpty);
      expect(feed(watch, [0]), [true]);
      expect(feed(watch, List.filled(500, 0)), isEmpty);
    });

    test('any sound brings it back, once', () {
      final watch = SilenceWatch(samples: 100);
      feed(watch, List.filled(100, 0));
      expect(feed(watch, [3, -2, 5]), [false]);
    });

    test('a quiet room is not silence: noise breaks the run', () {
      final watch = SilenceWatch(samples: 100);
      final quiet = [
        for (var i = 0; i < 1000; i++)
          if (i % 40 == 0) 1 else 0,
      ];
      expect(feed(watch, quiet), isEmpty);
    });

    test('reset forgets a run in progress', () {
      final watch = SilenceWatch(samples: 100);
      feed(watch, List.filled(80, 0));
      watch.reset();
      expect(feed(watch, List.filled(80, 0)), isEmpty);
    });
  });
}
