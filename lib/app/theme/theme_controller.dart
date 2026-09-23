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
  }

  /// Dark → Red night → Light → Dark, for the song view's quick switch.
  void cycle() {
    const values = AppThemeVariant.values;
    variant = values[(state.index + 1) % values.length];
  }
}
