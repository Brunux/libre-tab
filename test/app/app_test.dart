import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/app/router.dart';
import 'package:libre_tab/app/theme/app_theme.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';
import 'package:libre_tab/app/theme/theme_controller.dart';
import 'package:libre_tab/features/editor/presentation/song_editor_screen.dart';
import 'package:libre_tab/features/library/presentation/library_screen.dart';
import 'package:libre_tab/features/settings/presentation/settings_screen.dart';
import 'package:libre_tab/features/song_view/presentation/song_view_screen.dart';
import 'package:libre_tab/features/tuner/presentation/tuner_screen.dart';

import '../helpers/pump_app.dart';
import '../helpers/test_database.dart';

void main() {
  testWidgets('an unknown location, like a file URI, opens the Songbook', (
    tester,
  ) async {
    // Android hands a file opened from another app to Flutter as a route
    // unless deep linking is off; either way it must not be an error page.
    final container = await pumpApp(tester);
    container
        .read(routerProvider)
        .go('content://media/external/file/1000000020');
    await tester.pumpAndSettle();
    expect(find.byType(LibraryScreen), findsOneWidget);
    expect(find.textContaining('Page Not Found'), findsNothing);
  });

  testWidgets('back from Settings returns to the Songbook', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsNothing);
    expect(find.byType(LibraryScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('Save is disabled until the song has a title and text', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Add song'));
    await tester.pumpAndSettle();

    final save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save'),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('a theme picked in Settings applies everywhere', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    final library = tester.element(find.byType(LibraryScreen));
    expect(library.colors, LibreColors.light);
    final scaffold = tester.widget<Scaffold>(
      find.descendant(
        of: find.byType(LibraryScreen),
        matching: find.byType(Scaffold),
      ),
    );
    expect(
      scaffold.backgroundColor ?? Theme.of(library).scaffoldBackgroundColor,
      LibreColors.light.bg,
    );
  });

  testWidgets('Settings shows the theme chosen elsewhere', (tester) async {
    final container = await pumpApp(tester);
    container.read(themeVariantProvider.notifier).toggleRedNight();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    final picker = tester.widget<SegmentedButton<AppThemeVariant>>(
      find.byType(SegmentedButton<AppThemeVariant>),
    );
    expect(picker.selected, {AppThemeVariant.redNight});
  });

  testWidgets('each tab keeps its place when switching', (tester) async {
    final container = await pumpApp(tester);

    await tester.tap(navItem('Tuner'));
    await tester.pumpAndSettle();
    await tester.tap(navItem('Songbook'));
    await tester.pumpAndSettle();
    await tester.tap(navItem('Tuner'));
    await tester.pumpAndSettle();

    expect(currentPath(container), Routes.tuner);
    // Both tab screens stay alive (indexed stack), so state isn't lost.
    expect(find.byType(TunerScreen), findsOneWidget);
    expect(find.byType(LibraryScreen, skipOffstage: false), findsOneWidget);
  });

  testWidgets('the flame mark turns red in Red night', (tester) async {
    // Empty songbook: the mark in the header and in the empty message.
    final container = await pumpApp(tester);
    List<String> marks() => [
      for (final image in tester.widgetList<Image>(find.byType(Image)))
        (image.image as AssetImage).assetName,
    ];
    expect(marks(), everyElement('assets/images/mark.png'));
    expect(marks(), hasLength(2));

    container.read(themeVariantProvider.notifier).toggleRedNight();
    await tester.pumpAndSettle();
    expect(marks(), everyElement('assets/images/mark-red-night.png'));
  });

  testWidgets('starts on the Songbook tab', (tester) async {
    final container = await pumpApp(tester);

    expect(currentPath(container), Routes.songbook);
    // The logo heads every tab; the tab bar names the one you're on.
    expect(find.bySemanticsLabel('Libre Tab'), findsOneWidget);
    expect(find.text('Songbook'), findsOneWidget);
    expect(find.text('Add song'), findsOneWidget);
  });

  testWidgets('bottom tabs switch between Songbook and Tuner', (tester) async {
    final container = await pumpApp(tester);

    await tester.tap(navItem('Tuner'));
    await tester.pumpAndSettle();
    expect(currentPath(container), Routes.tuner);
    expect(find.byType(TunerScreen), findsOneWidget);

    await tester.tap(navItem('Songbook'));
    await tester.pumpAndSettle();
    expect(currentPath(container), Routes.songbook);
  });

  testWidgets('Add song opens full screen above the tabs', (tester) async {
    final container = await pumpApp(tester);

    await tester.tap(find.text('Add song'));
    await tester.pumpAndSettle();
    // Pushed routes don't change the base location, so check the screen.
    expect(find.byType(SongEditorScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    expect(currentPath(container), Routes.songbook);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('Settings changes the theme', (tester) async {
    final container = await pumpApp(tester);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tester.tap(find.text('Red night'));
    await tester.pumpAndSettle();
    expect(container.read(themeVariantProvider), AppThemeVariant.redNight);
    final context = tester.element(find.byType(SettingsScreen));
    expect(context.colors, LibreColors.redNight);
  });

  testWidgets('song view theme button cycles Dark → Red night → Light', (
    tester,
  ) async {
    final container = await pumpApp(tester, songs: [SampleSongs.amazingGrace]);

    container.read(routerProvider).go(Routes.song(1));
    await tester.pumpAndSettle();
    expect(find.byType(SongViewScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    // A tap: red night on, and off again (back to Dark).
    await tester.tap(find.byTooltip('Red night'));
    await tester.pump();
    expect(container.read(themeVariantProvider), AppThemeVariant.redNight);

    await tester.tap(find.byTooltip('Leave red night'));
    await tester.pump();
    expect(container.read(themeVariantProvider), AppThemeVariant.dark);

    // A long press: every theme to pick from.
    await tester.longPress(find.byTooltip('Red night'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, 'Light'));
    await tester.pumpAndSettle();
    expect(container.read(themeVariantProvider), AppThemeVariant.light);
  });

  testWidgets('shows Spanish text on a Spanish device', (tester) async {
    tester.platformDispatcher.localesTestValue = [const Locale('es')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await pumpApp(tester);

    expect(find.text('Cancionero'), findsOneWidget);
    expect(find.text('Afinador'), findsOneWidget);
    expect(find.text('Agregar canción'), findsOneWidget);
  });

  testWidgets('big screens get a side rail, phones a bottom bar', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 2;

    tester.view.physicalSize = const Size(2064, 2752); // iPad Pro 13"
    await pumpApp(tester);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    tester.view.physicalSize = const Size(860, 1864); // iPhone
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });
}
