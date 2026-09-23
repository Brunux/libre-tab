import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen on while a song is open, so it doesn't lock mid-verse.
/// Behind a provider so tests can fake it.
final keepAwakeProvider = Provider<KeepAwake>((ref) => const KeepAwake());

class KeepAwake {
  const KeepAwake();

  Future<void> enable() => WakelockPlus.enable();
  Future<void> disable() => WakelockPlus.disable();
}
