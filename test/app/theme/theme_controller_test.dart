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

  test('cycle goes Dark → Red night → Light → Dark', () {
    final seen = [
      for (var i = 0; i < 3; i++) (controller()..cycle()).variant,
    ];
    expect(seen, [
      AppThemeVariant.redNight,
      AppThemeVariant.light,
      AppThemeVariant.dark,
    ]);
  });

  test('variant setter selects a theme', () {
    controller().variant = AppThemeVariant.light;
    expect(container.read(themeVariantProvider), AppThemeVariant.light);
    expect(controller().variant, AppThemeVariant.light);
  });
}
