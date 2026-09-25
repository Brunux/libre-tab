// Recording settings are spelled out even where they match the package's
// defaults: pitch detection depends on them, whatever the defaults become.
// ignore_for_file: avoid_redundant_argument_values

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libre_tab/core/audio/pitch_worker.dart';
import 'package:record/record.dart';

enum MicAccess { granted, denied }

/// A frequency heard (null = silence) and the input level, 0–1.
typedef OnPitch = void Function(double? frequency, double level);

/// Where detected pitches come from. The app uses the microphone; tests
/// feed frequencies directly.
abstract interface class PitchSource {
  /// Starts listening and calls [onPitch] ~20 times a second with the
  /// frequency heard (null = silence) and how loud the sound is (0–1, so
  /// the tuner can show it's listening). With [ask], asks for the
  /// microphone if needed; without it only checks, so nothing pops up
  /// (used for the automatic restarts, e.g. coming back to the app).
  Future<MicAccess> start(OnPitch onPitch, {bool ask = true});

  Future<void> stop();
}

final pitchSourceProvider = Provider<PitchSource>((ref) {
  final source = MicPitchSource();
  ref.onDispose(source.dispose);
  return source;
});

/// Microphone → 4096-sample frames every 2048 samples (~46 ms at 44.1 kHz)
/// → [PitchWorker] on a background isolate (docs/TECH_STACK.md § Tuner).
class MicPitchSource implements PitchSource {
  static const sampleRate = 44100;
  static const frameSize = 4096;
  static const hop = 2048;

  final _recorder = AudioRecorder();
  PitchWorker? _worker;
  StreamSubscription<Uint8List>? _audio;
  final _pending = <double>[];
  var _busy = false;

  @override
  Future<MicAccess> start(OnPitch onPitch, {bool ask = true}) async {
    if (_audio != null) return MicAccess.granted;
    if (!await _recorder.hasPermission(request: ask)) return MicAccess.denied;
    _worker ??= await PitchWorker.start(sampleRate: sampleRate.toDouble());
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
        // Processing meant for voice calls would distort the pitch.
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
      ),
    );
    _audio = stream.listen((bytes) => _onAudio(bytes, onPitch));
    return MicAccess.granted;
  }

  void _onAudio(Uint8List bytes, OnPitch onPitch) {
    final data = ByteData.sublistView(bytes);
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      _pending.add(data.getInt16(i, Endian.little) / 32768);
    }
    while (_pending.length >= frameSize) {
      final frame = Float64List.fromList(_pending.sublist(0, frameSize));
      _pending.removeRange(0, hop);
      // Skip frames while the last one is still being analysed, so the
      // needle never lags behind the sound.
      if (_busy) continue;
      _busy = true;
      final level = levelOf(frame);
      unawaited(
        _worker!.detect(frame).then((frequency) {
          _busy = false;
          if (_audio != null) onPitch(frequency, level);
        }),
      );
    }
  }

  /// How loud [frame] is, 0–1: its RMS level from −70 dBFS (a quiet room)
  /// to −20 dBFS (a string played close by).
  static double levelOf(List<double> frame) {
    if (frame.isEmpty) return 0;
    var sum = 0.0;
    for (final s in frame) {
      sum += s * s;
    }
    final rms = math.sqrt(sum / frame.length);
    if (rms <= 0) return 0;
    final db = 20 * math.log(rms) / math.ln10;
    return ((db + 70) / 50).clamp(0.0, 1.0);
  }

  @override
  Future<void> stop() async {
    await _audio?.cancel();
    _audio = null;
    _pending.clear();
    if (await _recorder.isRecording()) await _recorder.stop();
  }

  Future<void> dispose() async {
    await stop();
    _worker?.dispose();
    await _recorder.dispose();
  }
}
