import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/core/audio/pitch_worker.dart';

Float64List sine(double frequency) => Float64List.fromList([
  for (var i = 0; i < 4096; i++)
    0.5 * math.sin(2 * math.pi * frequency * i / 44100),
]);

void main() {
  test('detects pitches on a background isolate', () async {
    final worker = await PitchWorker.start(sampleRate: 44100);
    addTearDown(worker.dispose);

    final results = await Future.wait([
      worker.detect(sine(110)),
      worker.detect(Float64List(4096)), // silence
      worker.detect(sine(329.63)),
    ]);

    expect(results[0], closeTo(110, 0.1));
    expect(results[1], isNull);
    expect(results[2], closeTo(329.63, 0.2));
  });

  test('dispose answers anything still waiting with null', () async {
    final worker = await PitchWorker.start(sampleRate: 44100);
    final pending = worker.detect(sine(110));
    worker.dispose();
    expect(await pending, anyOf(isNull, closeTo(110, 0.1)));
  });
}
