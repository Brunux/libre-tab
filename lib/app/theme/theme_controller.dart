import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libre_tab/app/theme/app_theme.dart';

/// The active theme. Kept in memory for now; persisted once Settings lands.
final themeVariantProvider =
    NotifierProvider<ThemeVariantController, AppThemeVariant>(
      ThemeVariantController.new,
    );

class ThemeVariantController extends Notifier<AppThemeVariant> {
  @override
  AppThemeVariant build() => AppThemeVariant.dark;

  AppThemeVariant get variant => state;
  set variant(AppThemeVariant variant) => state = variant;

  /// Dark → Red night → Light → Dark, for the song view's quick switch.
  void cycle() {
    const values = AppThemeVariant.values;
    state = values[(state.index + 1) % values.length];
  }
}
