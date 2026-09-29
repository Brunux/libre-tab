// Recording settings are spelled out even where they match the package's
// defaults: pitch detection depends on them, whatever the defaults become.
// ignore_for_file: avoid_redundant_argument_values

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libre_tab/core/audio/pitch_worker.dart';
import 'package:record/record.dart';

enum MicAccess {
  granted,
  denied,

  /// Allowed, but it couldn't be opened: another app has it (a call).
  busy,
}

/// A frequency heard (null = silence) and the input level, 0–1.
typedef OnPitch = void Function(double? frequency, double level);

/// The microphone was taken by another app (true), or came back (false).
typedef OnBusy = void Function({required bool busy});

/// Where detected pitches come from. The app uses the microphone; tests
/// feed frequencies directly.
abstract interface class PitchSource {
  /// Starts listening and calls [onPitch] ~20 times a second with the
  /// frequency heard (null = silence) and how loud the sound is (0–1, so
  /// the tuner can show it's listening). With [ask], asks for the
  /// microphone if needed; without it only checks, so nothing pops up
  /// (used for the automatic restarts, e.g. coming back to the app).
  /// [onBusy] reports another app taking the microphone while listening
  /// (a phone call, a voice recording) and giving it back.
  Future<MicAccess> start(OnPitch onPitch, {bool ask = true, OnBusy? onBusy});

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
  StreamSubscription<RecordState>? _state;
  final _pending = <double>[];
  final _silence = SilenceWatch(samples: sampleRate);
  var _busy = false;

  @override
  Future<MicAccess> start(
    OnPitch onPitch, {
    bool ask = true,
    OnBusy? onBusy,
  }) async {
    if (_audio != null) return MicAccess.granted;
    if (!await _recorder.hasPermission(request: ask)) return MicAccess.denied;
    _worker ??= await PitchWorker.start(sampleRate: sampleRate.toDouble());
    final Stream<Uint8List> stream;
    try {
      stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: 1,
          // Processing meant for voice calls would distort the pitch.
          autoGain: false,
          echoCancel: false,
          noiseSuppress: false,
          // A call pauses the recording; carry on when it's over.
          audioInterruption: AudioInterruptionMode.pauseResume,
        ),
      );
    } on Object {
      // iOS refuses to open the microphone during a call.
      await stop();
      return MicAccess.busy;
    }
    _silence.reset();
    _audio = stream.listen((bytes) => _onAudio(bytes, onPitch, onBusy));
    _state = _recorder.onStateChanged().listen((state) {
      if (_audio == null) return;
      onBusy?.call(busy: state != RecordState.record);
    }, onError: (Object _) {});
    return MicAccess.granted;
  }

  void _onAudio(Uint8List bytes, OnPitch onPitch, OnBusy? onBusy) {
    final data = ByteData.sublistView(bytes);
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      final sample = data.getInt16(i, Endian.little);
      if (_silence.add(sample) case final silenced?) {
        onBusy?.call(busy: silenced);
      }
      _pending.add(sample / 32768);
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
    await _state?.cancel();
    _state = null;
    _pending.clear();
    // Also when paused by a call: isRecording is false then.
    if (await _recorder.isRecording() || await _recorder.isPaused()) {
      await _recorder.stop();
    }
  }

  Future<void> dispose() async {
    await stop();
    _worker?.dispose();
    await _recorder.dispose();
  }
}

/// Spots a silenced microphone. On Android, while another app records (a
/// call, a voice recorder), the system keeps the stream going but fills it
/// with exact zeros; a real microphone always picks up a little noise.
class SilenceWatch {
  SilenceWatch({required this.samples});

  /// How many zero samples in a row count as silenced (one second).
  final int samples;

  var _zeros = 0;
  var _silenced = false;

  /// Takes one sample; returns true when the input has just been
  /// silenced, false when it has just come back, otherwise null.
  bool? add(int sample) {
    if (sample == 0) {
      if (_zeros < samples) _zeros++;
      if (_zeros == samples && !_silenced) return _silenced = true;
      return null;
    }
    _zeros = 0;
    if (!_silenced) return null;
    _silenced = false;
    return false;
  }

  void reset() {
    _zeros = 0;
    _silenced = false;
  }
}
