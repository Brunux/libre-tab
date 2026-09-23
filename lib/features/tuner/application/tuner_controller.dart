import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libre_tab/app/settings/settings_store.dart';
import 'package:libre_tab/core/music/tuner_reading.dart';
import 'package:libre_tab/core/music/tunings.dart';
import 'package:libre_tab/features/tuner/data/pitch_source.dart';

enum TunerStatus {
  /// Not listening (tab hidden, app in the background, or not started).
  idle,
  listening,

  /// The microphone permission was refused.
  denied,
}

final class TunerState {
  const TunerState({
    required this.tuning,
    required this.a4,
    this.status = TunerStatus.idle,
    this.lockedString,
    this.reading,
    this.inTune = false,
  });

  final TunerStatus status;
  final Tuning tuning;

  /// Reference pitch, 432–446 Hz.
  final int a4;

  /// The string being tuned when auto-detect is off.
  final int? lockedString;

  /// What's heard right now; null while silent.
  final TunerReading? reading;

  /// Held within ±5 cents long enough.
  final bool inTune;

  TunerState copyWith({
    TunerStatus? status,
    Tuning? tuning,
    int? a4,
    int? Function()? lockedString,
    TunerReading? Function()? reading,
    bool? inTune,
  }) => TunerState(
    status: status ?? this.status,
    tuning: tuning ?? this.tuning,
    a4: a4 ?? this.a4,
    lockedString: lockedString == null ? this.lockedString : lockedString(),
    reading: reading == null ? this.reading : reading(),
    inTune: inTune ?? this.inTune,
  );
}

/// Time since the tuner started; tests replace it with a fake clock.
final tunerClockProvider = Provider<Duration Function()>((ref) {
  final watch = Stopwatch()..start();
  return () => watch.elapsed;
});

final tunerProvider = NotifierProvider<TunerController, TunerState>(
  TunerController.new,
);

class TunerController extends Notifier<TunerState> {
  static const minA4 = 432;
  static const maxA4 = 446;

  final _smoother = TunerSmoother();

  SettingsStore get _store => ref.read(settingsStoreProvider);
  PitchSource get _source => ref.read(pitchSourceProvider);

  @override
  TunerState build() {
    final source = _source;
    ref.onDispose(() => unawaited(source.stop()));
    final saved = _store.getString(SettingsKeys.tuning);
    return TunerState(
      tuning: Tuning.values.firstWhere(
        (t) => t.name == saved,
        orElse: () => Tuning.standard,
      ),
      a4: (_store.getInt(SettingsKeys.a4) ?? 440).clamp(minA4, maxA4),
    );
  }

  /// Whether the microphone has been asked for before; if so the tuner
  /// starts by itself, otherwise it first explains why it needs it.
  bool get micAskedBefore => _store.getInt(SettingsKeys.micAsked) == 1;

  Future<void> start() async {
    if (state.status == TunerStatus.listening) return;
    _store.setInt(SettingsKeys.micAsked, 1);
    final access = await _source.start(_onPitch);
    state = state.copyWith(
      status: access == MicAccess.granted
          ? TunerStatus.listening
          : TunerStatus.denied,
    );
  }

  Future<void> stop() async {
    if (state.status != TunerStatus.listening) return;
    await _source.stop();
    _smoother.reset();
    state = state.copyWith(
      status: TunerStatus.idle,
      reading: () => null,
      inTune: false,
    );
  }

  Tuning get tuning => state.tuning;
  set tuning(Tuning tuning) {
    _store.setString(SettingsKeys.tuning, tuning.name);
    _changeTarget(state.copyWith(tuning: tuning, lockedString: () => null));
  }

  /// Locks the tuner to one string; tapping it again goes back to auto.
  void toggleString(int index) => _changeTarget(
    state.copyWith(
      lockedString: () => state.lockedString == index ? null : index,
    ),
  );

  void autoDetect() => _changeTarget(state.copyWith(lockedString: () => null));

  int get a4 => state.a4;
  set a4(int value) {
    final a4 = value.clamp(minA4, maxA4);
    _store.setInt(SettingsKeys.a4, a4);
    _changeTarget(state.copyWith(a4: a4));
  }

  /// After the target changes, the current sound is measured again.
  void _changeTarget(TunerState next) {
    _smoother.reset();
    final heard = next.reading?.frequency;
    state = next.copyWith(
      reading: () => heard == null ? null : _read(heard, next),
      inTune: false,
    );
  }

  TunerReading _read(double frequency, TunerState s) => TunerReading.of(
    frequency,
    tuning: s.tuning,
    lockedString: s.lockedString,
    a4: s.a4.toDouble(),
  );

  void _onPitch(double? frequency) {
    if (state.status != TunerStatus.listening) return;
    final smoothed = _smoother.add(frequency);
    final reading = smoothed == null ? null : _read(smoothed, state);
    final inTune = _smoother.inTune(reading, ref.read(tunerClockProvider)());
    if (inTune && !state.inTune) unawaited(HapticFeedback.mediumImpact());
    state = state.copyWith(reading: () => reading, inTune: inTune);
  }
}
