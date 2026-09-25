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
    this.level = 0,
    this.tuned = const {},
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

  /// How loud the microphone input is, 0–1 (falls back slowly).
  final double level;

  /// Strings that have been in tune since the tuner started, or since the
  /// tuning or A4 changed.
  final Set<int> tuned;

  bool get allTuned => tuned.length == tuning.strings.length;

  TunerState copyWith({
    TunerStatus? status,
    Tuning? tuning,
    int? a4,
    int? Function()? lockedString,
    TunerReading? Function()? reading,
    bool? inTune,
    double? level,
    Set<int>? tuned,
  }) => TunerState(
    status: status ?? this.status,
    tuning: tuning ?? this.tuning,
    a4: a4 ?? this.a4,
    lockedString: lockedString == null ? this.lockedString : lockedString(),
    reading: reading == null ? this.reading : reading(),
    inTune: inTune ?? this.inTune,
    level: level ?? this.level,
    tuned: tuned ?? this.tuned,
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

  /// Starts listening. Only a tap should [ask] for the microphone:
  /// automatic starts just check, because on Android asking pauses and
  /// resumes the app, which would start again and ask again, forever.
  Future<void> start({bool ask = true}) async {
    if (state.status == TunerStatus.listening) return;
    if (ask) _store.setInt(SettingsKeys.micAsked, 1);
    final access = await _source.start(_onPitch, ask: ask);
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
      level: 0,
      tuned: const {},
    );
  }

  Tuning get tuning => state.tuning;
  set tuning(Tuning tuning) {
    _store.setString(SettingsKeys.tuning, tuning.name);
    _changeTarget(
      state.copyWith(tuning: tuning, lockedString: () => null, tuned: const {}),
    );
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
    _changeTarget(state.copyWith(a4: a4, tuned: const {}));
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

  void _onPitch(double? frequency, double level) {
    if (state.status != TunerStatus.listening) return;
    final smoothed = _smoother.add(frequency);
    final reading = smoothed == null ? null : _read(smoothed, state);
    final inTune = _smoother.inTune(reading, ref.read(tunerClockProvider)());
    if (inTune && !state.inTune) unawaited(HapticFeedback.mediumImpact());
    final string = reading?.stringIndex;
    state = state.copyWith(
      reading: () => reading,
      inTune: inTune,
      // Up at once, down gently, so the listening ring breathes.
      level: level >= state.level ? level : state.level * 0.7 + level * 0.3,
      tuned: inTune && string != null && !state.tuned.contains(string)
          ? {...state.tuned, string}
          : null,
    );
  }
}
