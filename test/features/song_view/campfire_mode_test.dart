import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/app/router.dart';
import 'package:libre_tab/app/settings/settings_store.dart';
import 'package:libre_tab/app/theme/app_theme.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';
import 'package:libre_tab/features/song_view/presentation/song_view_screen.dart';
import 'package:libre_tab/features/song_view/presentation/widgets/chord_diagram.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_database.dart';

/// A song long enough to scroll.
final String longSong = [
  '{title: Long Song}',
  '{key: G}',
  for (var i = 0; i < 60; i++) '[G]La la la la la [C]la la la la line$i',
].join('\n');

Future<ProviderContainer> openSong(
  WidgetTester tester,
  String song, {
  FakeKeepAwake? keepAwake,
  SettingsStore? settings,
}) async {
  final container = await pumpApp(
    tester,
    songs: [song],
    keepAwake: keepAwake,
    settings: settings,
  );
  container.read(routerProvider).go(Routes.song(1));
  await tester.pumpAndSettle();
  return container;
}

/// The dock button with this tooltip.
IconButton dockButton(WidgetTester tester, String tooltip) =>
    tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip(tooltip),
        matching: find.byType(IconButton),
      ),
    );

double scrollOffset(WidgetTester tester) => tester
    .widget<SingleChildScrollView>(
      find
          .descendant(
            of: find.byType(SongViewScreen),
            matching: find.byType(SingleChildScrollView),
          )
          .first,
    )
    .controller!
    .offset;

void main() {
  testWidgets('the screen stays awake while a song is open', (tester) async {
    final keepAwake = FakeKeepAwake();
    await openSong(tester, SampleSongs.amazingGrace, keepAwake: keepAwake);
    expect(keepAwake.awake, isTrue);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(keepAwake.awake, isFalse);
  });

  testWidgets('the subtitle uses the body font, not the title font', (
    tester,
  ) async {
    await openSong(tester, SampleSongs.amazingGrace);
    final subtitle = tester.widget<Text>(find.text('John Newton · Key G'));
    expect(subtitle.style!.fontFamily, AppFonts.body);
  });

  group('transpose and capo', () {
    testWidgets('transposing changes every chord and the key', (tester) async {
      await openSong(tester, SampleSongs.amazingGrace);
      expect(find.text('G7'), findsOneWidget);

      await tester.tap(find.byTooltip('Transpose up'));
      await tester.tap(find.byTooltip('Transpose up'));
      await tester.pumpAndSettle();

      expect(find.text('A7'), findsOneWidget);
      expect(find.text('G7'), findsNothing);
      expect(find.text('John Newton · Key A'), findsOneWidget);
      expect(find.text('A (+2)'), findsOneWidget);

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byTooltip('Transpose down'));
      }
      await tester.pumpAndSettle();
      expect(find.text('F#7'), findsOneWidget);
      expect(find.text('F# (−1)'), findsOneWidget);
    });

    testWidgets('a capo shows easier shapes; the song still sounds the same', (
      tester,
    ) async {
      await openSong(tester, SampleSongs.amazingGrace);
      expect(dockButton(tester, 'Capo down').onPressed, isNull);

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byTooltip('Capo up'));
      }
      await tester.pumpAndSettle();

      expect(find.text('Sounds in G · Capo 3 · E shapes'), findsOneWidget);
      expect(find.text('E7'), findsOneWidget);
      expect(find.text('G7'), findsNothing);
    });

    testWidgets('a song written for a capo opens as written', (tester) async {
      // Oh! Susanna: {key: C} {capo: 2} → C shapes, sounds in D.
      await openSong(tester, SampleSongs.ohSusanna);
      expect(find.text('Sounds in D · Capo 2 · C shapes'), findsOneWidget);
      expect(find.text('C'), findsOneWidget); // chord as written
      expect(find.text('2'), findsOneWidget); // capo stepper

      await tester.tap(find.byTooltip('Capo down'));
      await tester.tap(find.byTooltip('Capo down'));
      await tester.pumpAndSettle();
      // No capo: the real chords.
      expect(find.text('Stephen Foster · Key D'), findsOneWidget);
      expect(find.text('D'), findsWidgets);
      expect(find.text('A'), findsOneWidget);
    });
  });

  group('text size', () {
    double lyricSize(WidgetTester tester) =>
        tester.widget<Text>(find.text('mazing ')).style!.fontSize!;

    testWidgets('A+ and A− resize the lyrics and are remembered', (
      tester,
    ) async {
      final settings = MemorySettingsStore();
      await openSong(tester, SampleSongs.amazingGrace, settings: settings);
      expect(lyricSize(tester), 22);

      await tester.tap(find.byTooltip('Larger text'));
      await tester.pumpAndSettle();
      expect(lyricSize(tester), 24);
      expect(settings.getInt(SettingsKeys.lyricsSize), 24);

      await tester.tap(find.byTooltip('Smaller text'));
      await tester.tap(find.byTooltip('Smaller text'));
      await tester.pumpAndSettle();
      expect(lyricSize(tester), 20);
    });

    testWidgets('the saved size is used, within limits', (tester) async {
      await openSong(
        tester,
        SampleSongs.amazingGrace,
        settings: MemorySettingsStore({SettingsKeys.lyricsSize: 16}),
      );
      expect(lyricSize(tester), 16);
      expect(dockButton(tester, 'Smaller text').onPressed, isNull);
    });
  });

  group('auto-scroll', () {
    testWidgets('Play scrolls the song; Pause stops it', (tester) async {
      await openSong(tester, longSong);
      final start = scrollOffset(tester);

      await tester.tap(find.byTooltip('Start auto-scroll'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      final moved = scrollOffset(tester);
      expect(moved, greaterThan(start));

      await tester.tap(find.byTooltip('Pause auto-scroll'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(scrollOffset(tester), moved);
    });

    testWidgets('while playing the dock folds down to the speed control', (
      tester,
    ) async {
      await openSong(tester, longSong);
      expect(find.byTooltip('Transpose up'), findsOneWidget);

      await tester.tap(find.byTooltip('Start auto-scroll'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // Key, capo and text size step aside; speed and pause stay.
      expect(find.byTooltip('Transpose up'), findsNothing);
      expect(find.byTooltip('Larger text'), findsNothing);
      expect(find.byTooltip('Scroll faster'), findsOneWidget);
      expect(find.text('SPEED 2'), findsOneWidget);

      // Pausing (here by tapping the lyrics) brings the whole dock back.
      await tester.tap(find.byTooltip('Pause auto-scroll'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byTooltip('Transpose up'), findsOneWidget);
    });

    testWidgets('the line under the title follows the song', (tester) async {
      await openSong(tester, longSong);
      double progress() => tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value!;
      expect(progress(), 0);

      await tester.tap(find.byTooltip('Start auto-scroll'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(progress(), greaterThan(0));
      expect(progress(), lessThan(1));
    });

    testWidgets('tapping the lyrics pauses and resumes', (tester) async {
      await openSong(tester, longSong);
      await tester.tap(find.text('line0'));
      await tester.pump();
      expect(find.byTooltip('Pause auto-scroll'), findsOneWidget);

      await tester.tap(find.text('line0'));
      await tester.pump();
      expect(find.byTooltip('Start auto-scroll'), findsOneWidget);
    });

    testWidgets('dragging moves the song, then auto-scroll carries on', (
      tester,
    ) async {
      await openSong(tester, longSong);
      await tester.tap(find.byTooltip('Start auto-scroll'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final before = scrollOffset(tester);
      await tester.drag(find.text('line3'), const Offset(0, -300));
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final afterDrag = scrollOffset(tester);
      expect(afterDrag, greaterThan(before + 200));
      // Still playing: no second tap needed.
      expect(find.byTooltip('Pause auto-scroll'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(scrollOffset(tester), greaterThan(afterDrag));
    });

    testWidgets('a finger on the lyrics holds the song still', (tester) async {
      await openSong(tester, longSong);
      await tester.tap(find.byTooltip('Start auto-scroll'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final finger = await tester.startGesture(
        tester.getCenter(find.text('line4')),
      );
      await tester.pump();
      final held = scrollOffset(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(scrollOffset(tester), held);

      // Moving the finger turns it into a scroll; auto-scroll then goes on.
      await finger.moveBy(const Offset(0, -60));
      await finger.moveBy(const Offset(0, -60));
      await finger.up();
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(find.byTooltip('Pause auto-scroll'), findsOneWidget);
      final settled = scrollOffset(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(scrollOffset(tester), greaterThan(settled));
    });

    testWidgets('the song opens at its first line, with room around it', (
      tester,
    ) async {
      await openSong(tester, longSong);
      final view = tester.getRect(find.byType(SingleChildScrollView));
      final room = scrollOffset(tester);
      // Room of half the visible height above the song, scrolled past.
      expect(room, closeTo(view.height / 2, 1));
      expect(tester.getTopLeft(find.text('line0')).dy, lessThan(view.top + 80));

      // Scrolled to the very end, the last line sits around the middle.
      final scroller = tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .controller!;
      scroller.jumpTo(scroller.position.maxScrollExtent);
      await tester.pump();
      final last = tester.getTopLeft(find.text('line59')).dy;
      expect(last, lessThan(view.center.dy));
      expect(last, greaterThan(view.top));
    });

    testWidgets('dragging while paused stays paused', (tester) async {
      await openSong(tester, longSong);
      await tester.drag(find.text('line3'), const Offset(0, -300));
      await tester.pumpAndSettle();
      final after = scrollOffset(tester);
      expect(find.byTooltip('Start auto-scroll'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(scrollOffset(tester), after);
    });

    testWidgets('it stops at the end of the song', (tester) async {
      await openSong(tester, longSong);
      await tester.tap(find.byTooltip('Start auto-scroll'));
      await tester.pump();
      for (var i = 0; i < 600; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.byTooltip('Start auto-scroll').evaluate().isNotEmpty) break;
      }
      expect(find.byTooltip('Start auto-scroll'), findsOneWidget);
      expect(find.text('line59'), findsOneWidget);
    });

    testWidgets('faster scrolls further, and the speed is remembered', (
      tester,
    ) async {
      final container = await openSong(tester, longSong);
      expect(find.text('SPEED 2'), findsOneWidget);

      await tester.tap(find.byTooltip('Scroll faster'));
      await tester.pumpAndSettle();
      expect(find.text('SPEED 3'), findsOneWidget);
      final saved = await container.read(songRepositoryProvider).getSong(1);
      expect(saved!.scrollSpeed, 3);

      final start = scrollOffset(tester);
      await tester.tap(find.byTooltip('Start auto-scroll'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      // Speed 3 is 15 px/s at the default text size.
      expect(scrollOffset(tester) - start, closeTo(30, 3));
    });
  });

  group('chord diagrams', () {
    testWidgets('tapping a chord shows how to play it', (tester) async {
      await openSong(tester, SampleSongs.amazingGrace);
      await tester.tap(find.text('G7'));
      await tester.pumpAndSettle();

      expect(find.byType(ChordDiagram), findsOneWidget);
      expect(find.textContaining('left: fret numbers'), findsOneWidget);
      // G7 = 3 2 0 0 0 1, read out string by string.
      expect(
        find.bySemanticsLabel(
          'Frets from the thickest string: 3, 2, open, open, open, 1',
        ),
        findsOneWidget,
      );
    });

    testWidgets('strings not played are said so', (tester) async {
      await openSong(tester, SampleSongs.amazingGrace);
      await tester.tap(find.text('C').first);
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(
          'Frets from the thickest string: not played, 3, 2, open, 1, open',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the diagram follows the transposed chord', (tester) async {
      await openSong(tester, SampleSongs.amazingGrace);
      await tester.tap(find.byTooltip('Transpose up'));
      await tester.pumpAndSettle();
      // G + 1 is A♭ (a flat key), so G7 becomes Ab7.
      await tester.tap(find.text('Ab7'));
      await tester.pumpAndSettle();
      final diagram = tester.widget<ChordDiagram>(find.byType(ChordDiagram));
      expect(diagram.voicing.toString(), '464544 (barre 4)');
    });

    testWidgets('chords without a diagram say so', (tester) async {
      await openSong(tester, '{title: Jazz}\n[Cdim]La');
      await tester.tap(find.text('Cdim'));
      await tester.pumpAndSettle();
      expect(find.text('No diagram for this chord yet.'), findsOneWidget);
    });

    testWidgets('the Chords menu shows every chord in the song once', (
      tester,
    ) async {
      await openSong(tester, SampleSongs.amazingGrace);
      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chords'));
      await tester.pumpAndSettle();
      // G, G7, C, D
      expect(find.byType(ChordDiagram), findsNWidgets(4));
    });
  });

  group('the theme is remembered', () {
    testWidgets('switching saves it', (tester) async {
      final settings = MemorySettingsStore();
      await openSong(tester, SampleSongs.amazingGrace, settings: settings);
      await tester.tap(find.byTooltip('Red night'));
      await tester.pumpAndSettle();
      expect(settings.getString(SettingsKeys.theme), 'redNight');
    });

    testWidgets('the app starts in the saved theme', (tester) async {
      await pumpApp(
        tester,
        settings: MemorySettingsStore({
          SettingsKeys.theme: AppThemeVariant.light.name,
        }),
      );
      final context = tester.element(find.byType(Scaffold).first);
      expect(context.colors, LibreColors.light);
    });
  });
}
