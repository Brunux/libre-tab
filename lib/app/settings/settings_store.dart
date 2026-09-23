import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libre_tab/app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small key–value settings. `main` swaps in [PrefsSettingsStore] so values
/// survive restarts; tests and the default use memory only.
final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => MemorySettingsStore(),
);

abstract interface class SettingsStore {
  String? getString(String key);
  int? getInt(String key);
  void setString(String key, String value);
  void setInt(String key, int value);
}

class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore([Map<String, Object>? values]) : _values = {...?values};

  final Map<String, Object> _values;

  @override
  String? getString(String key) => _values[key] as String?;
  @override
  int? getInt(String key) => _values[key] as int?;
  @override
  void setString(String key, String value) => _values[key] = value;
  @override
  void setInt(String key, int value) => _values[key] = value;
}

/// Backed by the platform's preferences, read into memory at startup.
/// Writes go to disk in the background.
class PrefsSettingsStore implements SettingsStore {
  PrefsSettingsStore(this._prefs);

  static Future<PrefsSettingsStore> load() async => PrefsSettingsStore(
    await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    ),
  );

  final SharedPreferencesWithCache _prefs;

  @override
  String? getString(String key) => _prefs.getString(key);
  @override
  int? getInt(String key) => _prefs.getInt(key);
  @override
  void setString(String key, String value) =>
      unawaited(_prefs.setString(key, value));
  @override
  void setInt(String key, int value) => unawaited(_prefs.setInt(key, value));
}

/// Keys, in one place.
abstract final class SettingsKeys {
  static const theme = 'theme';
  static const lyricsSize = 'lyricsSize';
}

/// Lyric text size on the song screen; chords follow at 85 %.
final lyricsSizeProvider = NotifierProvider<LyricsSizeController, double>(
  LyricsSizeController.new,
);

class LyricsSizeController extends Notifier<double> {
  static const min = 16.0;
  static const max = 36.0;
  static const step = 2.0;
  static const initial = 22.0;

  SettingsStore get _store => ref.read(settingsStoreProvider);

  @override
  double build() =>
      (_store.getInt(SettingsKeys.lyricsSize)?.toDouble() ?? initial).clamp(
        min,
        max,
      );

  bool get canShrink => state > min;
  bool get canGrow => state < max;

  void shrink() => _set(state - step);
  void grow() => _set(state + step);

  void _set(double size) {
    state = size.clamp(min, max);
    _store.setInt(SettingsKeys.lyricsSize, state.round());
  }
}

/// Reads a stored theme name, falling back to dark.
AppThemeVariant themeFromStore(SettingsStore store) {
  final name = store.getString(SettingsKeys.theme);
  return AppThemeVariant.values.firstWhere(
    (v) => v.name == name,
    orElse: () => AppThemeVariant.dark,
  );
}
