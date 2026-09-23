import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/app/router.dart';
import 'package:libre_tab/app/settings/settings_store.dart';
import 'package:libre_tab/core/database/app_database.dart';
import 'package:libre_tab/features/editor/presentation/song_editor_screen.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';
import 'package:libre_tab/features/song_view/presentation/song_view_screen.dart';

import '../helpers/pump_app.dart';
import '../helpers/test_database.dart';

/// A repository whose writes and list queries fail, to exercise error paths.
class _BrokenRepository extends SongRepository {
  _BrokenRepository(super.db);

  @override
  Future<int> addSong(String body) async => throw StateError('disk full');

  @override
  Stream<List<SongEntry>> watchSongs({
    String query = '',
    bool favoritesOnly = false,
  }) => Stream.error(StateError('corrupt'));
}

Future<void> goTo(
  WidgetTester tester,
  ProviderContainer container,
  String path,
) async {
  container.read(routerProvider).go(path);
  await tester.pumpAndSettle();
}

ScrollController songScroller(WidgetTester tester) => tester
    .widget<SingleChildScrollView>(
      find
          .descendant(
            of: find.byType(SongViewScreen),
            matching: find.byType(SingleChildScrollView),
          )
          .first,
    )
    .controller!;

final String longSong = [
  '{title: Long Song}',
  for (var i = 0; i < 60; i++) '[G]La la la la la [C]la la la line$i',
].join('\n');

void main() {
  group('error paths', () {
    testWidgets('the list says so when the songbook cannot be read', (
      tester,
    ) async {
      final db = testDatabase();
      addTearDown(db.close);
      await pumpApp(
        tester,
        overrides: [
          songRepositoryProvider.overrideWithValue(_BrokenRepository(db)),
        ],
      );
      expect(find.text("Couldn't open your songbook."), findsOneWidget);
    });

    testWidgets('a failed save keeps the text and says so', (tester) async {
      final db = testDatabase();
      addTearDown(db.close);
      await pumpApp(
        tester,
        overrides: [
          songRepositoryProvider.overrideWithValue(_BrokenRepository(db)),
        ],
      );
      await tester.tap(find.text('Add song'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Mine');
      await tester.enterText(find.byType(TextField).at(2), 'C\nLa la');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't save the song."), findsOneWidget);
      expect(find.byType(SongEditorScreen), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Mine'), findsOneWidget);
      // Save can be tried again.
      final save = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save'),
      );
      expect(save.onPressed, isNotNull);
    });

    testWidgets('editing a song that no longer exists', (tester) async {
      final container = await pumpApp(tester);
      await goTo(tester, container, Routes.editSong(999));
      expect(find.text("This song isn't in your songbook."), findsOneWidget);
      final save = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save'),
      );
      expect(save.onPressed, isNull);
    });
  });

  group('song screen edge cases', () {
    testWidgets('Chords on a song without chords says so', (tester) async {
      final container = await pumpApp(
        tester,
        songs: ['{title: Words}\nJust words to sing'],
      );
      await goTo(tester, container, Routes.song(1));
      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chords'));
      await tester.pumpAndSettle();
      expect(find.text('This song has no chords.'), findsOneWidget);
    });

    testWidgets('Play at the end of the song starts again from the top', (
      tester,
    ) async {
      final container = await pumpApp(tester, songs: [longSong]);
      await goTo(tester, container, Routes.song(1));
      final scroller = songScroller(tester)
        ..jumpTo(songScroller(tester).position.maxScrollExtent);
      await tester.pump();
      expect(scroller.offset, greaterThan(100));

      await tester.tap(find.byTooltip('Start auto-scroll'));
      await tester.pump();
      expect(scroller.offset, lessThan(10));
      expect(find.byTooltip('Pause auto-scroll'), findsOneWidget);
    });

    testWidgets('transpose stops at ±11 semitones', (tester) async {
      final container = await pumpApp(
        tester,
        songs: [SampleSongs.amazingGrace],
      );
      await goTo(tester, container, Routes.song(1));
      for (var i = 0; i < 11; i++) {
        await tester.tap(find.byTooltip('Transpose up'));
        await tester.pump();
      }
      final up = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip('Transpose up'),
          matching: find.byType(IconButton),
        ),
      );
      expect(up.onPressed, isNull);
      expect(find.text('F# (+11)'), findsOneWidget);
    });

    testWidgets('bigger text scrolls proportionally faster', (tester) async {
      final container = await pumpApp(
        tester,
        songs: [longSong],
        settings: MemorySettingsStore({SettingsKeys.lyricsSize: 33}),
      );
      await goTo(tester, container, Routes.song(1));
      await tester.tap(find.byTooltip('Start auto-scroll'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      // Speed 2 is 10 px/s at 22 px text, so 15 px/s at 33 px.
      expect(songScroller(tester).offset, closeTo(30, 3));
    });

    testWidgets('a very long title is cut with an ellipsis, not overflow', (
      tester,
    ) async {
      final container = await pumpApp(
        tester,
        songs: ['{title: ${'Very long title ' * 10}}\n[G]La'],
      );
      await goTo(tester, container, Routes.song(1));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('the Spanish dock', (tester) async {
    tester.platformDispatcher.localesTestValue = [const Locale('es')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final container = await pumpApp(tester, songs: [SampleSongs.ohSusanna]);
    await goTo(tester, container, Routes.song(1));

    for (final label in ['TONO', 'CEJILLA', 'LETRA', 'Velocidad 2']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    for (final tooltip in [
      'Subir tono',
      'Bajar cejilla',
      'Letra más grande',
      'Más rápido',
      'Iniciar desplazamiento',
    ]) {
      expect(find.byTooltip(tooltip), findsOneWidget, reason: tooltip);
    }
  });
}
