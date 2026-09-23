import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/app/router.dart';
import 'package:libre_tab/app/theme/app_theme.dart';
import 'package:libre_tab/app/theme/theme_controller.dart';

import '../helpers/pump_app.dart';
import '../helpers/test_database.dart';

/// Smallest phone we support (iPhone SE, 1st gen), in logical pixels.
const smallPhone = Size(320, 568);

void main() {
  group('layout: every screen fits a small phone with 200% text', () {
    for (final variant in AppThemeVariant.values) {
      for (final locale in const [Locale('en'), Locale('es')]) {
        testWidgets('${variant.name}, ${locale.languageCode}', (tester) async {
          tester.view
            ..physicalSize = smallPhone
            ..devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          tester.platformDispatcher
            ..textScaleFactorTestValue = 2
            ..localesTestValue = [locale];
          addTearDown(tester.platformDispatcher.clearAllTestValues);

          final container = await pumpApp(
            tester,
            songs: [SampleSongs.amazingGrace],
          );
          container.read(themeVariantProvider.notifier).variant = variant;

          for (final MapEntry(key: screen, value: path)
              in screenPaths.entries) {
            container.read(routerProvider).go(path);
            await tester.pumpAndSettle();
            // Overflows and other layout errors surface here.
            expect(tester.takeException(), isNull, reason: screen);
          }
        });
      }
    }
  });

  testWidgets(
    'screen titles are left-aligned on every screen',
    (tester) async {
      final container = await pumpApp(
        tester,
        songs: [SampleSongs.amazingGrace],
      );
      for (final MapEntry(key: screen, value: path) in screenPaths.entries) {
        container.read(routerProvider).go(path);
        await tester.pumpAndSettle();
        final title = find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(Text),
        );
        if (title.evaluate().isEmpty) continue; // e.g. "song not found"
        // Left edge of the title, allowing for a back/close button.
        expect(
          tester.getTopLeft(title.first).dx,
          lessThan(80),
          reason: screen,
        );
      }
    },
    variant: TargetPlatformVariant.mobile(),
  );

  group('accessibility guidelines on every screen', () {
    for (final variant in AppThemeVariant.values) {
      testWidgets(variant.name, (tester) async {
        final semantics = tester.ensureSemantics();
        final container = await pumpApp(
          tester,
          songs: [SampleSongs.amazingGrace],
        );
        container.read(themeVariantProvider.notifier).variant = variant;

        for (final path in screenPaths.values) {
          container.read(routerProvider).go(path);
          await tester.pumpAndSettle();
          // Touch targets ≥ 48 px (Android) / 44 px (iOS), every tappable
          // thing has a label, and drawn text is readable.
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        }
        semantics.dispose();
      });
    }
  });
}
