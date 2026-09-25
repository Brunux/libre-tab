import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/app/settings/settings_store.dart';
import 'package:libre_tab/core/widgets/motion.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';
import 'package:libre_tab/features/song_view/presentation/song_view_screen.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_database.dart';

const List<String> _all = [
  SampleSongs.ohSusanna, // id 1
  SampleSongs.amazingGrace, // id 2
  SampleSongs.cancion, // id 3
];

/// Song titles on screen, top to bottom.
List<String> shownTitles(WidgetTester tester) {
  const titles = {'Amazing Grace', 'Canción de cuna', 'Oh! Susanna'};
  final texts = find.byType(Text).evaluate().map((e) => e.widget as Text);
  return [
    for (final t in texts)
      if (titles.contains(t.data)) t.data!,
  ];
}

void main() {
  testWidgets('an empty songbook shows the first-run message', (tester) async {
    await pumpApp(tester);
    expect(find.textContaining('Your songbook is empty'), findsOneWidget);
  });

  testWidgets('lists songs by title with key, artist and capo', (tester) async {
    await pumpApp(tester, songs: _all);

    expect(find.text('3 SONGS'), findsOneWidget);
    expect(shownTitles(tester), [
      'Amazing Grace',
      'Canción de cuna',
      'Oh! Susanna',
    ]);
    expect(find.text('John Newton'), findsOneWidget);
    expect(find.text('Stephen Foster · Capo 2'), findsOneWidget);
    expect(find.text('G'), findsOneWidget); // key badges
    expect(find.text('C'), findsOneWidget);
    // No {key} line: the first chord's key, as the song view shows it.
    expect(find.text('Am'), findsOneWidget);
    expect(find.byIcon(Icons.music_note), findsNothing);
  });

  testWidgets('a song with no chords at all shows a note', (tester) async {
    await pumpApp(tester, songs: ['{title: Words only}\nJust lyrics']);
    expect(find.byIcon(Icons.music_note), findsOneWidget);
  });

  testWidgets('search filters as you type and ignores accents', (tester) async {
    await pumpApp(tester, songs: _all);

    await tester.enterText(find.byType(TextField), 'cancion');
    await tester.pumpAndSettle();
    expect(shownTitles(tester), ['Canción de cuna']);
    expect(find.text('1 SONG'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'wretch');
    await tester.pumpAndSettle();
    expect(shownTitles(tester), ['Amazing Grace']);
  });

  testWidgets('no matches, then clearing the search', (tester) async {
    await pumpApp(tester, songs: _all);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No songs match your search.'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(shownTitles(tester), hasLength(3));
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
    expect(find.byTooltip('Clear search'), findsNothing);
  });

  testWidgets('favorites filter', (tester) async {
    final container = await pumpApp(tester, songs: _all);

    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No favorites yet'), findsOneWidget);

    await container.read(songRepositoryProvider).setFavorite(1, favorite: true);
    await tester.pumpAndSettle();
    expect(shownTitles(tester), ['Oh! Susanna']);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);

    await tester.tap(find.text('All songs'));
    await tester.pumpAndSettle();
    expect(shownTitles(tester), hasLength(3));
  });

  testWidgets('empty states offer the way out', (tester) async {
    await pumpApp(tester, songs: _all);

    // No favorites: "Browse songs" goes back to all of them.
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Browse songs'));
    await tester.pumpAndSettle();
    expect(shownTitles(tester), hasLength(3));

    // No matches: the button under the message clears the search.
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Clear search'));
    await tester.pumpAndSettle();
    expect(shownTitles(tester), hasLength(3));
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
  });

  group('play history and sorting', () {
    Future<void> openAndBack(WidgetTester tester, String title) async {
      await tester.tap(find.text(title).first);
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    testWidgets('a song opened shows under Recently played', (tester) async {
      await pumpApp(tester, songs: _all);
      expect(find.text('RECENTLY PLAYED'), findsNothing);

      await openAndBack(tester, 'Oh! Susanna');
      expect(find.text('RECENTLY PLAYED'), findsOneWidget);
      // The card, and the row in the list.
      expect(find.text('Oh! Susanna'), findsNWidgets(2));
    });

    testWidgets('sorting by most played says how often, and is kept', (
      tester,
    ) async {
      final settings = MemorySettingsStore();
      await pumpApp(tester, songs: _all, settings: settings);
      await openAndBack(tester, 'Oh! Susanna');
      await openAndBack(tester, 'Oh! Susanna');
      await openAndBack(tester, 'Amazing Grace');

      await tester.tap(find.text('A–Z'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Most played'));
      await tester.pumpAndSettle();

      expect(find.text('Stephen Foster · Capo 2 · Played 2×'), findsOneWidget);
      expect(find.text('John Newton · Played once'), findsOneWidget);
      expect(settings.getString(SettingsKeys.songSort), 'mostPlayed');
      // Recently played stays above (only a Recent sort would repeat it).
      expect(find.text('RECENTLY PLAYED'), findsOneWidget);
      // The rows come after the cards: Oh! Susanna (2 plays) first.
      final rows = shownTitles(tester);
      expect(
        rows.lastIndexOf('Oh! Susanna'),
        lessThan(rows.lastIndexOf('Amazing Grace')),
      );
    });

    testWidgets('sorted by recent, rows say when', (tester) async {
      await pumpApp(
        tester,
        songs: _all,
        settings: MemorySettingsStore({SettingsKeys.songSort: 'recent'}),
      );
      await openAndBack(tester, 'Amazing Grace');
      expect(find.text('John Newton · Played today'), findsOneWidget);
      expect(find.text('RECENTLY PLAYED'), findsNothing);
      expect(shownTitles(tester).first, 'Amazing Grace');
    });

    testWidgets('searching lists best matches, without the sort menu', (
      tester,
    ) async {
      await pumpApp(tester, songs: _all);
      await tester.enterText(find.byType(TextField), 'grace');
      await tester.pumpAndSettle();
      expect(find.text('A–Z'), findsNothing);
    });

    testWidgets('a long songbook gets an A–Z index that jumps', (tester) async {
      final many = [
        for (final letter in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''))
          for (var n = 1; n <= 2; n++) '{title: $letter song $n}\n[G]La',
      ];
      await pumpApp(tester, songs: many);
      expect(find.text('Z song 1'), findsNothing);

      // The index is left out for screen readers, so find its letters by
      // text: the last "Z" on screen is the index's.
      await tester.tap(find.text('Z').last);
      await tester.pumpAndSettle();
      expect(find.text('Z song 1'), findsOneWidget);
    });
  });

  testWidgets('the title flies into the song view and back', (tester) async {
    await pumpApp(tester, songs: _all);
    await tester.tap(find.text('Amazing Grace'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150)); // mid-flight
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.byType(SongViewScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    // Back, now with a Recently played card too: still one flying title.
    await tester.tap(find.text('Amazing Grace').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(SongViewScreen), findsOneWidget);
  });

  group('motion', () {
    testWidgets('a deleted row folds away; Undo grows it back', (tester) async {
      final container = await pumpApp(tester, songs: _all);
      await tester.drag(find.text('Amazing Grace'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Still folding: the song is only deleted once the row is gone.
      expect(find.text('Amazing Grace'), findsOneWidget);
      expect(
        await container.read(songRepositoryProvider).getSong(2),
        isNotNull,
      );
      await tester.pumpAndSettle();
      expect(find.text('Amazing Grace'), findsNothing);

      await tester.tap(find.text('Undo'));
      // Frame by frame: the row comes back small and grows to full height.
      final row = find.ancestor(
        of: find.text('Amazing Grace'),
        matching: find.byType(Appearing),
      );
      final heights = <double>[];
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (row.evaluate().isNotEmpty) heights.add(tester.getSize(row).height);
      }
      await tester.pumpAndSettle();
      expect(heights.first, lessThan(tester.getSize(row).height));
    });

    testWidgets('songs added together cascade in', (tester) async {
      final container = await pumpApp(tester);
      await container.read(songRepositoryProvider).importSongs(_all);
      Finder row(String title) =>
          find.ancestor(of: find.text(title), matching: find.byType(Appearing));
      var cascaded = false;
      for (var i = 0; i < 40 && !cascaded; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final rows = ['Amazing Grace', 'Oh! Susanna'];
        if (rows.every((t) => row(t).evaluate().isNotEmpty)) {
          // The first row is further along than the last.
          cascaded =
              tester.getSize(row(rows.first)).height >
              tester.getSize(row(rows.last)).height;
        }
      }
      expect(cascaded, isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('Reduce Motion: the title stays put, rows go at once', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final container = await pumpApp(tester, songs: _all);
      expect(
        tester
            .widgetList<HeroMode>(find.byType(HeroMode))
            .map((h) => h.enabled),
        everyElement(isFalse),
      );

      await tester.drag(find.text('Amazing Grace'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump();
      expect(await container.read(songRepositoryProvider).getSong(2), isNull);
    });
  });

  testWidgets('tapping a song opens it', (tester) async {
    await pumpApp(tester, songs: _all);

    await tester.tap(find.text('Amazing Grace'));
    await tester.pumpAndSettle();
    expect(find.byType(SongViewScreen), findsOneWidget);
    expect(find.text('John Newton · Key G'), findsOneWidget);
  });

  group('swipe actions', () {
    Future<void> swipeLeft(WidgetTester tester, String title) async {
      await tester.drag(find.text(title), const Offset(-500, 0));
      await tester.pumpAndSettle();
    }

    testWidgets('swiping left shows Setlist, Share and Delete', (tester) async {
      await pumpApp(tester, songs: _all);
      await swipeLeft(tester, 'Amazing Grace');

      expect(find.text('Setlist'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('Delete removes the song at once, and Undo brings it back', (
      tester,
    ) async {
      final container = await pumpApp(tester, songs: _all);
      final songs = container.read(songRepositoryProvider);
      await swipeLeft(tester, 'Amazing Grace');
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Amazing Grace'), findsNothing);
      expect(find.text('Deleted “Amazing Grace”.'), findsOneWidget);
      expect(await songs.getSong(2), isNull);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(await songs.getSong(2), isNotNull);
      expect(find.text('Amazing Grace'), findsOneWidget);
    });

    testWidgets('Share shares the song file', (tester) async {
      final files = FakeSongFiles();
      await pumpApp(tester, songs: _all, files: files);
      await swipeLeft(tester, 'Oh! Susanna');
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(files.shared.single.title, 'Oh! Susanna');
    });

    testWidgets('Setlist opens the Add to setlist sheet', (tester) async {
      await pumpApp(tester, songs: _all);
      await swipeLeft(tester, 'Oh! Susanna');
      await tester.tap(find.text('Setlist'));
      await tester.pumpAndSettle();
      expect(find.text('Add to setlist'), findsOneWidget);
      expect(find.text('New setlist'), findsOneWidget);
    });

    testWidgets('screen readers get the same actions', (tester) async {
      await pumpApp(tester, songs: _all);
      final node = tester.getSemantics(find.text('Amazing Grace'));
      final ids = node.getSemanticsData().customSemanticsActionIds ?? [];
      final labels = [
        for (final int id in ids) CustomSemanticsAction.getAction(id)!.label,
      ];
      expect(labels, ['Add to setlist', 'Share', 'Delete']);
    });
  });
}
