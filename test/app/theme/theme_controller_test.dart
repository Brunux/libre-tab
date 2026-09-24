import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/app/theme/app_theme.dart';
import 'package:libre_tab/app/theme/theme_controller.dart';

void main() {
  late ProviderContainer container;
  ThemeVariantController controller() =>
      container.read(themeVariantProvider.notifier);

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('starts dark', () {
    expect(container.read(themeVariantProvider), AppThemeVariant.dark);
  });

  test('the red-night switch goes back to Dark from Dark', () {
    controller().toggleRedNight();
    expect(controller().variant, AppThemeVariant.redNight);
    controller().toggleRedNight();
    expect(controller().variant, AppThemeVariant.dark);
  });

  test('the red-night switch goes back to Light from Light', () {
    controller().variant = AppThemeVariant.light;
    controller().toggleRedNight();
    expect(controller().variant, AppThemeVariant.redNight);
    controller().toggleRedNight();
    expect(controller().variant, AppThemeVariant.light);
  });

  test('red night chosen outright goes back to the last day theme', () {
    controller().variant = AppThemeVariant.light;
    controller().variant = AppThemeVariant.redNight;
    controller().toggleRedNight();
    expect(controller().variant, AppThemeVariant.light);
  });

  test('variant setter selects a theme', () {
    controller().variant = AppThemeVariant.light;
    expect(container.read(themeVariantProvider), AppThemeVariant.light);
    expect(controller().variant, AppThemeVariant.light);
  });
}
