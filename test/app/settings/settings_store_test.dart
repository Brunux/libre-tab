import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/app/settings/settings_store.dart';
import 'package:libre_tab/app/theme/app_theme.dart';
import 'package:libre_tab/app/theme/theme_controller.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrefsSettingsStore (the real, on-device store)', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('values survive a restart', () async {
      final first = await PrefsSettingsStore.load();
      first
        ..setString(SettingsKeys.theme, 'redNight')
        ..setInt(SettingsKeys.lyricsSize, 28);
      await pumpEventQueue();

      // "Restart": a fresh store reading the same platform storage.
      final second = await PrefsSettingsStore.load();
      expect(second.getString(SettingsKeys.theme), 'redNight');
      expect(second.getInt(SettingsKeys.lyricsSize), 28);
    });

    test('empty on first launch', () async {
      final store = await PrefsSettingsStore.load();
      expect(store.getString(SettingsKeys.theme), isNull);
      expect(store.getInt(SettingsKeys.lyricsSize), isNull);
    });
  });

  group('theme and text size from settings', () {
    ProviderContainer containerWith(Map<String, Object> values) {
      final container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(MemorySettingsStore(values)),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('an unknown saved theme falls back to dark', () {
      final container = containerWith({SettingsKeys.theme: 'neon'});
      expect(container.read(themeVariantProvider), AppThemeVariant.dark);
    });

    test('a saved text size outside the limits is clamped', () {
      expect(
        containerWith({SettingsKeys.lyricsSize: 99}).read(lyricsSizeProvider),
        LyricsSizeController.max,
      );
      expect(
        containerWith({SettingsKeys.lyricsSize: 2}).read(lyricsSizeProvider),
        LyricsSizeController.min,
      );
    });

    test('text size stops at its limits', () {
      final container = containerWith({SettingsKeys.lyricsSize: 34});
      final size = container.read(lyricsSizeProvider.notifier);
      expect(size.canGrow, isTrue);
      size
        ..grow()
        ..grow();
      expect(container.read(lyricsSizeProvider), 36);
      expect(size.canGrow, isFalse);
    });
  });
}
