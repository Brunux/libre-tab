import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen on while a song or the tuner is open. Behind a provider
/// so tests can fake it.
final keepAwakeProvider = Provider<KeepAwake>((ref) => KeepAwake());

/// Counted: the screen stays on while any screen still wants it, so the
/// tuner going quiet (e.g. a song opened on top of it) can't switch it off
/// under the song.
class KeepAwake {
  var _requests = 0;

  bool get awake => _requests > 0;

  Future<void> enable() async {
    if (_requests++ == 0) await WakelockPlus.enable();
  }

  Future<void> disable() async {
    if (_requests == 0) return;
    if (--_requests == 0) await WakelockPlus.disable();
  }
}
