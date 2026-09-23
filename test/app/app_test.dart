import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/app/router.dart';
import 'package:libre_tab/app/theme/app_theme.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';
import 'package:libre_tab/app/theme/theme_controller.dart';
import 'package:libre_tab/features/editor/presentation/add_song_screen.dart';
import 'package:libre_tab/features/library/presentation/library_screen.dart';
import 'package:libre_tab/features/settings/presentation/settings_screen.dart';
import 'package:libre_tab/features/song_view/presentation/song_view_screen.dart';
import 'package:libre_tab/features/tuner/presentation/tuner_screen.dart';

import '../helpers/pump_app.dart';

void main() {
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

  testWidgets('Save is disabled until the importer exists', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Add song'));
    await tester.pumpAndSettle();

    final save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save'),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('a theme picked in Settings applies everywhere', (
    tester,
  ) async {
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
    container.read(themeVariantProvider.notifier).cycle(); // → Red night

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

  testWidgets('starts on the Songbook tab', (tester) async {
    final container = await pumpApp(tester);

    expect(currentPath(container), Routes.songbook);
    expect(find.text('Songbook'), findsNWidgets(2)); // title + tab label
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
    expect(find.byType(AddSongScreen), findsOneWidget);
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
    final container = await pumpApp(tester);

    container.read(routerProvider).go(Routes.song('demo'));
    await tester.pumpAndSettle();
    expect(find.byType(SongViewScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byTooltip('Switch theme'));
    await tester.pump();
    expect(container.read(themeVariantProvider), AppThemeVariant.redNight);

    await tester.tap(find.byTooltip('Switch theme'));
    await tester.pump();
    expect(container.read(themeVariantProvider), AppThemeVariant.light);
  });

  testWidgets('shows Spanish text on a Spanish device', (tester) async {
    tester.platformDispatcher.localesTestValue = [const Locale('es')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await pumpApp(tester);

    expect(find.text('Cancionero'), findsNWidgets(2));
    expect(find.text('Afinador'), findsOneWidget);
    expect(find.text('Agregar canción'), findsOneWidget);
  });
}
