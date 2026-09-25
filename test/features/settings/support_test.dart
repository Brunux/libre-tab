import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/app/router.dart';
import 'package:libre_tab/app/settings/settings_store.dart';
import 'package:libre_tab/core/device/support_channel.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_database.dart';

Future<void> openSupport(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('Star it on GitHub'),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> tapOption(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pump();
}

void main() {
  group('Support Libre Tab', () {
    testWidgets('rate, share and GitHub, everywhere', (tester) async {
      final support = FakeSupport();
      await pumpApp(tester, support: support);
      await openSupport(tester);
      expect(find.text('Keep the campfire burning'), findsOneWidget);

      await tapOption(tester, 'Rate Libre Tab');
      await tapOption(tester, 'Share with a friend');
      await tapOption(tester, 'Star it on GitHub');
      expect(support.rated, 1);
      expect(support.shared.single, contains('github.com/Brunux/libre-tab'));
      expect(support.opened, [SupportLink.github]);
    });

    testWidgets('no coffee link on Android', (tester) async {
      await pumpApp(tester, support: FakeSupport(country: 'USA'));
      await openSupport(tester);
      expect(find.text('Buy me a coffee'), findsNothing);
    });

    testWidgets('the coffee link only in the US App Store', (tester) async {
      final us = FakeSupport(country: 'USA');
      await pumpApp(tester, support: us);
      await openSupport(tester);
      await tapOption(tester, 'Buy me a coffee');
      expect(us.opened, [SupportLink.coffee]);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('no coffee link in other App Store countries', (tester) async {
      await pumpApp(tester, support: FakeSupport(country: 'MEX'));
      await openSupport(tester);
      expect(find.text('Buy me a coffee'), findsNothing);
      expect(find.text('Rate Libre Tab'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  });

  group('the thank-you after 10 songs', () {
    testWidgets('opening songs counts toward it', (tester) async {
      final settings = MemorySettingsStore();
      final container = await pumpApp(
        tester,
        songs: [SampleSongs.amazingGrace],
        settings: settings,
      );
      container.read(routerProvider).go(Routes.song(1));
      await tester.pumpAndSettle();
      expect(settings.getInt(SettingsKeys.songsOpened), 1);
    });

    testWidgets('shows once; "Maybe later" puts it away for good', (
      tester,
    ) async {
      final settings = MemorySettingsStore({SettingsKeys.songsOpened: 10});
      await pumpApp(
        tester,
        songs: [SampleSongs.amazingGrace],
        settings: settings,
      );
      expect(find.text('10 songs by the fire!'), findsOneWidget);

      await tester.tap(find.text('Maybe later'));
      await tester.pumpAndSettle();
      expect(find.text('10 songs by the fire!'), findsNothing);
      expect(settings.getInt(SettingsKeys.supportNudged), 1);
    });

    testWidgets('"How can I help?" shows the ways to help', (tester) async {
      await pumpApp(
        tester,
        songs: [SampleSongs.amazingGrace],
        settings: MemorySettingsStore({SettingsKeys.songsOpened: 12}),
      );
      await tester.tap(find.text('How can I help?'));
      await tester.pumpAndSettle();
      expect(find.text('Rate Libre Tab'), findsOneWidget);
      expect(find.text('10 songs by the fire!'), findsNothing);
    });

    testWidgets('not before the 10th song', (tester) async {
      await pumpApp(
        tester,
        songs: [SampleSongs.amazingGrace],
        settings: MemorySettingsStore({SettingsKeys.songsOpened: 9}),
      );
      expect(find.text('10 songs by the fire!'), findsNothing);
    });
  });
}
