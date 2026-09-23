import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:libre_tab/core/audio/pitch_detector.dart';

/// Runs [PitchDetector] on a background isolate, so the tuner's needle
/// stays smooth while each frame is analysed.
class PitchWorker {
  PitchWorker._(this._isolate, this._requests, this._replies) {
    _replies.listen((message) {
      final (id, frequency) = message! as (int, double?);
      _pending.remove(id)?.complete(frequency);
    });
  }

  static Future<PitchWorker> start({required double sampleRate}) async {
    final replies = ReceivePort();
    final isolate = await Isolate.spawn(_run, (replies.sendPort, sampleRate));
    final messages = replies.asBroadcastStream();
    final requests = await messages.first as SendPort;
    return PitchWorker._(isolate, requests, messages);
  }

  final Isolate _isolate;
  final SendPort _requests;
  final Stream<Object?> _replies;
  final _pending = <int, Completer<double?>>{};
  var _nextId = 0;

  /// The frequency of [samples] in Hz, or null for silence or no clear note.
  Future<double?> detect(Float64List samples) {
    final id = _nextId++;
    final completer = _pending[id] = Completer<double?>();
    _requests.send((id, TransferableTypedData.fromList([samples])));
    return completer.future;
  }

  void dispose() {
    _isolate.kill(priority: Isolate.immediate);
    for (final pending in _pending.values) {
      pending.complete(null);
    }
    _pending.clear();
  }

  static void _run((SendPort, double) args) {
    final (replies, sampleRate) = args;
    final detector = PitchDetector(sampleRate: sampleRate);
    final requests = ReceivePort();
    replies.send(requests.sendPort);
    requests.listen((message) {
      final (id, data) = message! as (int, TransferableTypedData);
      final samples = data.materialize().asFloat64List();
      replies.send((id, detector.detect(samples)?.frequency));
    });
  }
}
