import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libre_tab/app/settings/settings_store.dart';
import 'package:libre_tab/app/theme/app_theme.dart';

/// The active theme, remembered between launches.
final themeVariantProvider =
    NotifierProvider<ThemeVariantController, AppThemeVariant>(
      ThemeVariantController.new,
    );

class ThemeVariantController extends Notifier<AppThemeVariant> {
  SettingsStore get _store => ref.read(settingsStoreProvider);

  @override
  AppThemeVariant build() => themeFromStore(_store);

  AppThemeVariant get variant => state;
  set variant(AppThemeVariant variant) {
    state = variant;
    _store.setString(SettingsKeys.theme, variant.name);
    if (variant != AppThemeVariant.redNight) {
      _store.setString(SettingsKeys.dayTheme, variant.name);
    }
  }

  /// The song view's quick switch: red night on, or back off to the theme
  /// it came from (Dark or Light), so a tap always does the same thing.
  void toggleRedNight() {
    if (state != AppThemeVariant.redNight) {
      variant = AppThemeVariant.redNight;
      return;
    }
    final day = _store.getString(SettingsKeys.dayTheme);
    variant = day == AppThemeVariant.light.name
        ? AppThemeVariant.light
        : AppThemeVariant.dark;
  }
}
